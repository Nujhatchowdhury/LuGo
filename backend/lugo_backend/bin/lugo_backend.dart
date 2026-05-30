import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';

/// =======================
/// DATABASE CONNECTION
/// =======================
Future<MySqlConnection> connectDB() async {
  final dotenv = DotEnv(includePlatformEnvironment: true)..load();

  return await MySqlConnection.connect(
    ConnectionSettings(
      host: dotenv['DB_HOST'] ?? '127.0.0.1',
      port: int.tryParse(dotenv['DB_PORT'] ?? '') ?? 3306,
      user: dotenv['DB_USER'] ?? 'root',
      password: dotenv['DB_PASSWORD'] ?? '',
      db: dotenv['DB_NAME'] ?? 'lugo_bus',
    ),
  );
}

/// =======================
/// OTP GENERATOR
/// =======================
String generateOTP() {
  final rand = Random();
  return (100000 + rand.nextInt(900000)).toString();
}

String normalizeRole(dynamic rawRole) {
  final role = rawRole?.toString().toLowerCase();
  return role == 'driver' ? 'driver' : 'student';
}

bool isBlank(dynamic value) => value == null || value.toString().trim().isEmpty;

final RegExp studentEmailPattern = RegExp(r'^[a-z]+_018\d{13}@lus\.ac\.bd$');
final RegExp driverEmailPattern = RegExp(
  r'^[a-z][a-z0-9._%+-]*@lus\.ac\.bd$',
);
final RegExp campusEmailPattern = RegExp(
  r'^(?:[a-z]+_018\d{13}|[a-z][a-z0-9._%+-]*)@lus\.ac\.bd$',
);
final RegExp studentIdPattern = RegExp(r'^018\d{13}$');
final RegExp driverIdPattern = RegExp(r'^4\d{4}$');
final RegExp phonePattern = RegExp(r'^\+880\d{10}$');

String? extractStudentOrDriverId(String? rawValue) {
  final value = rawValue?.trim().toLowerCase();
  if (value == null || value.isEmpty) {
    return null;
  }

  if (studentIdPattern.hasMatch(value) || driverIdPattern.hasMatch(value)) {
    return value;
  }

  final emailMatch = RegExp(
    r'^(?:[a-z]+_)?(018\d{13})@lus\.ac\.bd$',
  ).firstMatch(value);
  return emailMatch?.group(1);
}

String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) {
    return email;
  }

  final local = parts.first;
  final domain = parts.last;
  if (local.length <= 2) {
    return '${local[0]}***@$domain';
  }

  return '${local.substring(0, 2)}${'*' * (local.length - 2)}@$domain';
}

String? validateRegistrationFields({
  required String? name,
  required String? email,
  required String? studentOrDriverId,
  required String? phone,
  required String? password,
  required String role,
}) {
  if (isBlank(name) ||
      isBlank(email) ||
      isBlank(studentOrDriverId) ||
      isBlank(phone) ||
      isBlank(password)) {
    return 'Please fill in all registration fields.';
  }

  final normalizedEmail = email!.trim().toLowerCase();
  final normalizedId = studentOrDriverId!.trim();
  final normalizedRole = normalizeRole(role);

  if (normalizedRole == 'driver') {
    if (!driverEmailPattern.hasMatch(normalizedEmail)) {
      return 'Driver email must look like name@lus.ac.bd.';
    }
    if (!driverIdPattern.hasMatch(normalizedId)) {
      return 'Driver ID must be 5 digits and start with 4.';
    }
  } else {
    if (!studentEmailPattern.hasMatch(normalizedEmail)) {
      return 'Student email must look like dept_018xxxxxxxxxxxxx@lus.ac.bd.';
    }
    if (!studentIdPattern.hasMatch(normalizedId)) {
      return 'Student ID must start with 018 and be exactly 16 digits.';
    }
  }
  if (!phonePattern.hasMatch(phone!.trim())) {
    return 'Phone number must be in +880XXXXXXXXXX format.';
  }

  if (password!.length < 6) {
    return 'Password must be at least 6 characters.';
  }

  return null;
}

bool isValidLoginIdentifier(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }

  return studentEmailPattern.hasMatch(normalized) ||
      driverEmailPattern.hasMatch(normalized) ||
      studentIdPattern.hasMatch(normalized) ||
      driverIdPattern.hasMatch(normalized);
}

bool smtpConfigured(DotEnv dotenv) {
  return !isBlank(dotenv['SMTP_HOST']) &&
      !isBlank(dotenv['SMTP_PORT']) &&
      !isBlank(dotenv['SMTP_USERNAME']) &&
      !isBlank(dotenv['SMTP_PASSWORD']) &&
      !isBlank(dotenv['SMTP_FROM']);
}

String sqlValue(dynamic value) {
  if (value == null) {
    return 'NULL';
  }

  final escaped = value
      .toString()
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'");
  return "'$escaped'";
}

Future<String> runMysqlCliQuery(DotEnv dotenv, String sql) async {
  final args = <String>[
    '-u',
    dotenv['DB_USER'] ?? 'root',
    '-D',
    dotenv['DB_NAME'] ?? 'lugo_bus',
    '-N',
    '-B',
    '-e',
    sql,
  ];

  final password = dotenv['DB_PASSWORD'] ?? '';
  if (password.isNotEmpty) {
    args.insertAll(2, ['-p$password']);
  }

  final host = dotenv['DB_HOST'] ?? '';
  if (host.isNotEmpty) {
    args.insertAll(0, ['-h', host]);
  }

  final port = dotenv['DB_PORT'] ?? '';
  if (port.isNotEmpty) {
    args.insertAll(0, ['-P', port]);
  }

  final result = await Process.run('mysql', args);
  if (result.exitCode != 0) {
    throw Exception(result.stderr.toString().trim());
  }

  return result.stdout.toString().trim();
}

Future<void> sendOtpEmail({
  required DotEnv dotenv,
  required String recipientEmail,
  required String recipientName,
  required String otp,
  String subject = 'Your LuGo OTP Code',
  String introLine = 'Your LuGo verification code is:',
  String actionLine = 'Enter this OTP in the app to verify your account.',
}) async {
  final smtpServer = SmtpServer(
    dotenv['SMTP_HOST']!,
    port: int.tryParse(dotenv['SMTP_PORT'] ?? '') ?? 587,
    username: dotenv['SMTP_USERNAME'],
    password: dotenv['SMTP_PASSWORD'],
    ssl: (dotenv['SMTP_SSL'] ?? '').toLowerCase() == 'true',
    allowInsecure: (dotenv['SMTP_ALLOW_INSECURE'] ?? '').toLowerCase() == 'true',
  );

  final message = Message()
    ..from = Address(
      dotenv['SMTP_FROM']!,
      dotenv['SMTP_FROM_NAME'] ?? 'LuGo Bus',
    )
    ..recipients.add(recipientEmail)
    ..subject = subject
    ..text = '''
Hello $recipientName,

${introLine.trim()} $otp

$actionLine

Thanks,
LuGo Bus
'''
    ..html = '''
<p>Hello ${htmlEscape.convert(recipientName)},</p>
<p>${htmlEscape.convert(introLine)}</p>
<h2 style="letter-spacing:4px;">${htmlEscape.convert(otp)}</h2>
<p>${htmlEscape.convert(actionLine)}</p>
<p>Thanks,<br>LuGo Bus</p>
''';

  await send(message, smtpServer);
}

/// =======================
/// MAIN SERVER
/// =======================
void main() async {
  final dotenv = DotEnv(includePlatformEnvironment: true)..load();
  final router = Router();

  Response jsonResponse(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // =======================
  // HOME ROUTE
  // =======================
  router.get('/', (Request req) {
    return jsonResponse({
      'message': 'LuGo Backend Running 🚍',
      'databaseHost': dotenv['DB_HOST'] ?? '127.0.0.1',
      'databaseName': dotenv['DB_NAME'] ?? 'lugo_bus',
    });
  });

  // =======================
  // REGISTER USER
  // =======================
  router.post('/register', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final name = body['name']?.toString().trim();
      final email = body['email']?.toString().trim().toLowerCase();
      final studentOrDriverId = body['student_id']?.toString().trim();
      final phone = body['phone']?.toString().trim();
      final password = body['password']?.toString();

      final validationMessage = validateRegistrationFields(
        name: name,
        email: email,
        studentOrDriverId: studentOrDriverId,
        phone: phone,
        password: password,
        role: body['role']?.toString() ?? 'student',
      );
      if (validationMessage != null) {
        return jsonResponse(
          {'success': false, 'message': validationMessage},
          statusCode: 400,
        );
      }

      final existingUserCountOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT COUNT(*)
        FROM users
        WHERE email = ${sqlValue(email)}
        ''',
      );
      final existingUserCount = int.tryParse(existingUserCountOutput) ?? 0;
      if (existingUserCount > 0) {
        return jsonResponse(
          {
            'success': false,
            'message': 'This email is already registered. Please log in or use a different email.',
          },
          statusCode: 409,
        );
      }

      final existingIdCountOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT COUNT(*)
        FROM users
        WHERE student_or_driver_id = ${sqlValue(studentOrDriverId)}
        ''',
      );
      final existingIdCount = int.tryParse(existingIdCountOutput) ?? 0;
      if (existingIdCount > 0) {
        return jsonResponse(
          {
            'success': false,
            'message': 'This student or driver ID is already registered.',
          },
          statusCode: 409,
        );
      }

      conn = await connectDB();
      final otp = generateOTP();
      final role = normalizeRole(body['role']);

      await conn.query('''
        INSERT INTO users (
          name,
          email,
          student_or_driver_id,
          phone,
          password,
          role,
          otp,
          is_verified
        ) VALUES (
          ${sqlValue(name)},
          ${sqlValue(email)},
          ${sqlValue(studentOrDriverId)},
          ${sqlValue(phone)},
          ${sqlValue(password)},
          ${sqlValue(role)},
          ${sqlValue(otp)},
          0
        )
      ''');

      var emailDelivered = false;
      String? emailDeliveryError;
      if (smtpConfigured(dotenv)) {
        try {
          await sendOtpEmail(
            dotenv: dotenv,
            recipientEmail: email!,
            recipientName: name!,
            otp: otp,
          );
          emailDelivered = true;
        } catch (error) {
          emailDeliveryError = error.toString();
        }
      }

      return jsonResponse({
        'success': true,
        'message': emailDelivered
            ? 'User registered successfully. OTP sent to your email.'
            : 'User registered successfully.',
        'otp': emailDelivered ? null : otp,
        'emailDelivered': emailDelivered,
        'emailDeliveryError': emailDeliveryError,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Registration failed',
        'error': error.toString(),
        'databaseHost': dotenv['DB_HOST'] ?? '127.0.0.1',
        'databaseName': dotenv['DB_NAME'] ?? 'lugo_bus',
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  router.post('/forgot-password', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final email = body['email']?.toString().trim().toLowerCase();
      final studentOrDriverId = extractStudentOrDriverId(email);

      if (isBlank(email) || !campusEmailPattern.hasMatch(email!)) {
        return jsonResponse(
          {
            'success': false,
            'message': 'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
          },
          statusCode: 400,
        );
      }

      final userName = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT CONCAT(name, '\t', email)
        FROM users
        WHERE (
            email = ${sqlValue(email)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND is_verified = 1
        LIMIT 1
        ''',
      );

      if (userName.isEmpty) {
        return jsonResponse(
          {
            'success': false,
            'message': 'No verified account was found for that email.',
          },
          statusCode: 404,
        );
      }

      final userParts = userName.split('\t');
      final recipientName = userParts.isNotEmpty ? userParts.first : 'LuGo User';
      final registeredEmail = userParts.length > 1 ? userParts[1] : email;

      final otp = generateOTP();
      final escapedEmail = sqlValue(email);
      final escapedId = sqlValue(studentOrDriverId);
      await runMysqlCliQuery(
        dotenv,
        '''
        UPDATE users
        SET otp = ${sqlValue(otp)}
        WHERE email = $escapedEmail
           OR student_or_driver_id = $escapedId
        ''',
      );

      var emailDelivered = false;
      String? emailDeliveryError;
      if (smtpConfigured(dotenv)) {
        try {
          await sendOtpEmail(
            dotenv: dotenv,
            recipientEmail: registeredEmail,
            recipientName: recipientName,
            otp: otp,
            subject: 'Your LuGo password reset code',
            introLine: 'Your LuGo password reset code is:',
            actionLine: 'Enter this OTP in the app to reset your password.',
          );
          emailDelivered = true;
        } catch (error) {
          emailDeliveryError = error.toString();
        }
      }

      return jsonResponse({
        'success': true,
        'message': emailDelivered
            ? 'Reset OTP sent to your registered email.'
            : 'Reset OTP generated successfully.',
        'otp': emailDelivered ? null : otp,
        'emailDelivered': emailDelivered,
        'emailDeliveryError': emailDeliveryError,
        'sentTo': emailDelivered ? maskEmail(registeredEmail) : null,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Password reset request failed',
        'error': error.toString(),
      }, statusCode: 500);
    }
  });

  router.post('/verify-reset-otp', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final email = body['email']?.toString().trim().toLowerCase();
      final studentOrDriverId = extractStudentOrDriverId(email);
      final otp = body['otp']?.toString().trim();

      if (isBlank(email) || !campusEmailPattern.hasMatch(email!)) {
        return jsonResponse(
          {
            'success': false,
            'message': 'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
          },
          statusCode: 400,
        );
      }

      if (isBlank(otp) || otp!.length != 6) {
        return jsonResponse(
          {'success': false, 'message': 'Enter the 6-digit OTP.'},
          statusCode: 400,
        );
      }

      final matchedCountOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT COUNT(*)
        FROM users
        WHERE (
            email = ${sqlValue(email)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND otp = ${sqlValue(otp)}
          AND is_verified = 1
        ''',
      );
      final matchedCount = int.tryParse(matchedCountOutput) ?? 0;

      if (matchedCount == 0) {
        return jsonResponse(
          {'success': false, 'message': 'Invalid OTP or email.'},
          statusCode: 403,
        );
      }

      return jsonResponse({
        'success': true,
        'message': 'OTP verified successfully.',
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Reset OTP verification failed',
        'error': error.toString(),
      }, statusCode: 500);
    }
  });

  router.post('/reset-password', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final email = body['email']?.toString().trim().toLowerCase();
      final studentOrDriverId = extractStudentOrDriverId(email);
      final otp = body['otp']?.toString().trim();
      final newPassword = body['newPassword']?.toString();

      if (isBlank(email) || !campusEmailPattern.hasMatch(email!)) {
        return jsonResponse(
          {
            'success': false,
            'message': 'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
          },
          statusCode: 400,
        );
      }

      if (isBlank(otp) || otp!.length != 6) {
        return jsonResponse(
          {'success': false, 'message': 'Enter the 6-digit OTP.'},
          statusCode: 400,
        );
      }

      if (isBlank(newPassword) || newPassword!.length < 6) {
        return jsonResponse(
          {
            'success': false,
            'message': 'New password must be at least 6 characters.',
          },
          statusCode: 400,
        );
      }

      conn = await connectDB();
      final result = await conn.query('''
        UPDATE users
        SET password = ${sqlValue(newPassword)},
            otp = NULL
        WHERE (
            email = ${sqlValue(email)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND otp = ${sqlValue(otp)}
          AND is_verified = 1
      ''');

      final matchedCountOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT COUNT(*)
        FROM users
        WHERE (
            email = ${sqlValue(email)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND password = ${sqlValue(newPassword)}
          AND is_verified = 1
        ''',
      );
      final matchedCount = int.tryParse(matchedCountOutput) ?? 0;

      if ((result.affectedRows ?? 0) == 0 && matchedCount == 0) {
        return jsonResponse(
          {'success': false, 'message': 'Invalid OTP or email.'},
          statusCode: 403,
        );
      }

      return jsonResponse({
        'success': true,
        'message': 'Password updated successfully. Please log in.',
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Password reset failed',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  // =======================
  // VERIFY OTP
  // =======================
  router.post('/verify', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());

      conn = await connectDB();

      final result = await conn.query('''
        UPDATE users
        SET is_verified = 1
        WHERE email = ${sqlValue(body['email'])}
          AND otp = ${sqlValue(body['otp'])}
      ''');

      final matchedCountOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT COUNT(*)
        FROM users
        WHERE email = ${sqlValue(body['email'])}
          AND otp = ${sqlValue(body['otp'])}
          AND is_verified = 1
        ''',
      );
      final matchedCount = int.tryParse(matchedCountOutput) ?? 0;

      if ((result.affectedRows ?? 0) == 0 && matchedCount == 0) {
        return jsonResponse(
          {'success': false, 'message': 'Invalid OTP'},
          statusCode: 403,
        );
      }

      return jsonResponse({
        'success': true,
        'message': 'Email verified successfully',
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'OTP verification failed',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  // =======================
  // LOGIN
  // =======================
  router.post('/login', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final identifier = body['email']?.toString().trim().toLowerCase();
      final studentOrDriverId = extractStudentOrDriverId(identifier);
      final password = body['password']?.toString();

      if (!isValidLoginIdentifier(identifier) || isBlank(password)) {
        return jsonResponse(
          {
            'success': false,
            'message':
                'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd, a driver email like name@lus.ac.bd, a 16-digit student ID, or a 5-digit driver ID starting with 4.',
          },
          statusCode: 400,
        );
      }

      conn = await connectDB();
      final roleOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT CAST(role AS CHAR)
        FROM users
        WHERE (
            email = ${sqlValue(identifier)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND password = ${sqlValue(password)}
          AND is_verified = 1
        ORDER BY
          CASE
            WHEN email = ${sqlValue(identifier)} THEN 0
            WHEN email LIKE '%@lus.ac.bd' THEN 1
            ELSE 2
          END,
          id DESC
        LIMIT 1
        ''',
      );

      if (roleOutput.isEmpty) {
        return jsonResponse(
          {'success': false, 'message': 'Login failed'},
          statusCode: 403,
        );
      }

      return jsonResponse({
        'success': true,
        'message': 'Login success 🚍',
        'role': roleOutput,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Login failed',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  // =======================
  // SERVER HANDLER
  // =======================
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 8080);

  print('🚀 LuGo Server running on http://${server.address.host}:${server.port}');
}
