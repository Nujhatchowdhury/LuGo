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

bool brevoConfigured(DotEnv dotenv) {
  return !isBlank(dotenv['BREVO_API_KEY']) && !isBlank(dotenv['EMAIL_FROM']);
}

String sqlValue(dynamic value) {
  if (value == null) {
    return 'NULL';
  }

  final escaped =
      value.toString().replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}

Future<String> runMysqlCliQuery(DotEnv dotenv, String sql) async {
  final args = <String>[
    if (!isBlank(dotenv['DB_HOST'])) ...[
      '-h',
      dotenv['DB_HOST']!,
    ],
    if (!isBlank(dotenv['DB_PORT'])) ...[
      '-P',
      dotenv['DB_PORT']!,
    ],
    if ((dotenv['DB_DISABLE_SSL'] ?? '').toLowerCase() == 'true') '--ssl=0',
    '-u',
    dotenv['DB_USER'] ?? 'root',
    if (!isBlank(dotenv['DB_PASSWORD'])) '-p${dotenv['DB_PASSWORD']}',
    '-D',
    dotenv['DB_NAME'] ?? 'lugo_bus',
    '-N',
    '-B',
    '-e',
    sql,
  ];

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
  bool allowAppleMailFallback = false,
}) async {
  if (brevoConfigured(dotenv)) {
    try {
      await sendOtpEmailWithBrevo(
        dotenv: dotenv,
        recipientEmail: recipientEmail,
        recipientName: recipientName,
        otp: otp,
        subject: subject,
        introLine: introLine,
        actionLine: actionLine,
      );
      return;
    } catch (_) {
      if (!allowAppleMailFallback || !Platform.isMacOS) {
        rethrow;
      }
    }
  }

  try {
    final smtpServer = SmtpServer(
      dotenv['SMTP_HOST']!,
      port: int.tryParse(dotenv['SMTP_PORT'] ?? '') ?? 587,
      username: dotenv['SMTP_USERNAME'],
      password: dotenv['SMTP_PASSWORD'],
      ssl: (dotenv['SMTP_SSL'] ?? '').toLowerCase() == 'true',
      allowInsecure:
          (dotenv['SMTP_ALLOW_INSECURE'] ?? '').toLowerCase() == 'true',
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

    await send(message, smtpServer).timeout(const Duration(seconds: 6));
    return;
  } catch (_) {
    if (!allowAppleMailFallback || !Platform.isMacOS) {
      rethrow;
    }
  }

  await sendOtpEmailWithAppleMail(
    recipientEmail: recipientEmail,
    recipientName: recipientName,
    otp: otp,
    subject: subject,
    introLine: introLine,
    actionLine: actionLine,
  );
}

String appleScriptString(String value) {
  return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}

Future<void> sendOtpEmailWithAppleMail({
  required String recipientEmail,
  required String recipientName,
  required String otp,
  required String subject,
  required String introLine,
  required String actionLine,
}) async {
  final content = '''
Hello $recipientName,

${introLine.trim()} $otp

$actionLine

Thanks,
LuGo Bus
''';

  final script = '''
tell application "Mail"
  set newMessage to make new outgoing message with properties {subject:${appleScriptString(subject)}, content:${appleScriptString(content)}}
  tell newMessage
    make new to recipient at end of to recipients with properties {address:${appleScriptString(recipientEmail)}}
    set visible to false
    send
  end tell
end tell
''';

  final result = await Process.run('osascript', ['-e', script]).timeout(
    const Duration(seconds: 10),
  );
  if (result.exitCode != 0) {
    throw Exception(result.stderr.toString().trim());
  }
}

Future<void> sendOtpEmailWithBrevo({
  required DotEnv dotenv,
  required String recipientEmail,
  required String recipientName,
  required String otp,
  required String subject,
  required String introLine,
  required String actionLine,
}) async {
  final fromEmail = dotenv['EMAIL_FROM']!;
  final fromName = dotenv['EMAIL_FROM_NAME'] ?? 'LuGo Bus';
  final client = HttpClient();
  try {
    final request = await client
        .postUrl(Uri.parse('https://api.brevo.com/v3/smtp/email'))
        .timeout(const Duration(seconds: 6));
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set('api-key', dotenv['BREVO_API_KEY']!);

    request.write(jsonEncode({
      'sender': {
        'name': fromName,
        'email': fromEmail,
      },
      'to': [
        {
          'email': recipientEmail,
          'name': recipientName,
        }
      ],
      'subject': subject,
      'textContent': '''
Hello $recipientName,

${introLine.trim()} $otp

$actionLine

Thanks,
LuGo Bus
''',
      'htmlContent': '''
<p>Hello ${htmlEscape.convert(recipientName)},</p>
<p>${htmlEscape.convert(introLine)}</p>
<h2 style="letter-spacing:4px;">${htmlEscape.convert(otp)}</h2>
<p>${htmlEscape.convert(actionLine)}</p>
<p>Thanks,<br>LuGo Bus</p>
''',
    }));

    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await utf8.decodeStream(response).timeout(
          const Duration(seconds: 4),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Brevo email failed (${response.statusCode}): $body');
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> ensureAppSchema(DotEnv dotenv) async {
  await runMysqlCliQuery(
    dotenv,
    '''
      CREATE TABLE IF NOT EXISTS bus_rsvps (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        student_email VARCHAR(255) NOT NULL,
        route_name VARCHAR(120) NOT NULL,
        pickup_location VARCHAR(255) NOT NULL,
        ride_time VARCHAR(30) NOT NULL,
        ride_date DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_student_ride (
          student_email,
          route_name,
          ride_time,
          ride_date
        )
      )
    ''',
  );
  await runMysqlCliQuery(
    dotenv,
    '''
      CREATE TABLE IF NOT EXISTS admin_notifications (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        target_email VARCHAR(255) DEFAULT NULL,
        title VARCHAR(180) NOT NULL,
        message TEXT NOT NULL,
        ride_date DATE DEFAULT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''',
  );
  await runMysqlCliQuery(
    dotenv,
    '''
      CREATE TABLE IF NOT EXISTS bus_locations (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        driver_email VARCHAR(255) NOT NULL,
        route_name VARCHAR(120) NOT NULL,
        latitude DOUBLE NOT NULL,
        longitude DOUBLE NOT NULL,
        accuracy DOUBLE DEFAULT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
          ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_driver_route (driver_email, route_name)
      )
    ''',
  );
}

Map<String, int> calculateBusAllocation(int rsvpCount) {
  if (rsvpCount <= 0) {
    return {'largeBuses': 0, 'smallBuses': 0, 'totalSeats': 0};
  }

  final largeBuses = rsvpCount ~/ 48;
  final remaining = rsvpCount % 48;
  if (remaining == 0) {
    return {
      'largeBuses': largeBuses,
      'smallBuses': 0,
      'totalSeats': largeBuses * 48,
    };
  }

  if (remaining <= 26) {
    return {
      'largeBuses': largeBuses,
      'smallBuses': 1,
      'totalSeats': largeBuses * 48 + 26,
    };
  }

  return {
    'largeBuses': largeBuses + 1,
    'smallBuses': 0,
    'totalSeats': (largeBuses + 1) * 48,
  };
}

List<Map<String, dynamic>> parseAvailabilityRows(String output) {
  if (output.trim().isEmpty) {
    return [];
  }

  return output.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
    final parts = line.split('\t');
    final count = int.tryParse(parts.length > 4 ? parts[4] : '0') ?? 0;
    final rsvps = parts.length > 5 && parts[5].trim().isNotEmpty
        ? parts[5]
            .split(',')
            .map((email) => email.trim())
            .where((email) => email.isNotEmpty)
            .toList()
        : <String>[];
    final allocation = calculateBusAllocation(count);
    return {
      'route': parts.isNotEmpty ? parts[0] : '',
      'pickupLocation': parts.length > 1 ? parts[1] : '',
      'rideTime': parts.length > 2 ? parts[2] : '',
      'rideDate': parts.length > 3 ? parts[3] : '',
      'rsvpCount': count,
      'rsvps': rsvps,
      ...allocation,
    };
  }).toList();
}

String buildAvailabilityMessage(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) {
    return 'No student RSVPs were found for tomorrow yet.';
  }

  return rows.map((row) {
    return '${row['route']} at ${row['rideTime']} from ${row['pickupLocation']}: '
        '${row['rsvpCount']} RSVPs, ${row['largeBuses']} large bus(es), '
        '${row['smallBuses']} small bus(es), ${row['totalSeats']} seats.';
  }).join('\n');
}

/// =======================
/// MAIN SERVER
/// =======================
void main() async {
  final dotenv = DotEnv(includePlatformEnvironment: true)..load();
  await ensureAppSchema(dotenv);
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
            'message':
                'This email is already registered. Please log in or use a different email.',
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
            'message':
                'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
          },
          statusCode: 400,
        );
      }

      final userRow = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT id, name, email
        FROM users
        WHERE (
            email = ${sqlValue(email)}
            OR student_or_driver_id = ${sqlValue(studentOrDriverId)}
          )
          AND is_verified = 1
        ORDER BY
          CASE
            WHEN email = ${sqlValue(email)} THEN 0
            ELSE 1
          END,
          id DESC
        LIMIT 1
        ''',
      );

      if (userRow.isEmpty) {
        return jsonResponse(
          {
            'success': false,
            'message': 'No verified account was found for that email.',
          },
          statusCode: 404,
        );
      }

      final userParts = userRow.split('\t');
      final userId = userParts.isNotEmpty ? userParts[0] : '';
      final recipientName = userParts.length > 1 ? userParts[1] : 'LuGo User';
      final registeredEmail = userParts.length > 2 ? userParts[2] : email;
      final recipientEmail = email;

      final otp = generateOTP();
      await runMysqlCliQuery(
        dotenv,
        '''
        UPDATE users
        SET otp = ${sqlValue(otp)},
            email = ${sqlValue(recipientEmail)}
        WHERE id = ${sqlValue(userId)}
        ''',
      );

      var emailDelivered = false;
      String? emailDeliveryError;
      if (brevoConfigured(dotenv) || smtpConfigured(dotenv)) {
        try {
          await sendOtpEmail(
            dotenv: dotenv,
            recipientEmail: recipientEmail,
            recipientName: recipientName,
            otp: otp,
            subject: 'Your LuGo password reset code',
            introLine: 'Your LuGo password reset code is:',
            actionLine: 'Enter this OTP in the app to reset your password.',
            allowAppleMailFallback: true,
          );
          emailDelivered = true;
        } catch (error) {
          emailDeliveryError = error.toString();
        }
      }

      return jsonResponse({
        'success': emailDelivered,
        'message': emailDelivered
            ? 'Reset OTP sent to your email.'
            : 'Email delivery is not configured yet. Please contact the LuGo admin.',
        'otp': null,
        'emailDelivered': emailDelivered,
        'emailDeliveryError': emailDeliveryError,
        'sentTo': emailDelivered ? maskEmail(recipientEmail) : null,
        'previousEmail': registeredEmail == recipientEmail
            ? null
            : maskEmail(registeredEmail),
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
            'message':
                'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
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
            'message':
                'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
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

  router.post('/bus-rsvp', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final studentEmail =
          body['studentEmail']?.toString().trim().toLowerCase();
      final routeName = body['routeName']?.toString().trim();
      final pickupLocation = body['pickupLocation']?.toString().trim();
      final rideTime = body['rideTime']?.toString().trim();
      final rideDate = body['rideDate']?.toString().trim();

      if (isBlank(studentEmail) ||
          !studentEmailPattern.hasMatch(studentEmail!)) {
        return jsonResponse(
          {
            'success': false,
            'message':
                'Use your student email like dept_018xxxxxxxxxxxxx@lus.ac.bd.',
          },
          statusCode: 400,
        );
      }

      if (isBlank(routeName) ||
          isBlank(pickupLocation) ||
          isBlank(rideTime) ||
          isBlank(rideDate)) {
        return jsonResponse(
          {
            'success': false,
            'message': 'Choose route, pickup location, time, and date.',
          },
          statusCode: 400,
        );
      }

      conn = await connectDB();
      await conn.query('''
        INSERT INTO bus_rsvps (
          student_email,
          route_name,
          pickup_location,
          ride_time,
          ride_date
        ) VALUES (
          ${sqlValue(studentEmail)},
          ${sqlValue(routeName)},
          ${sqlValue(pickupLocation)},
          ${sqlValue(rideTime)},
          ${sqlValue(rideDate)}
        )
        ON DUPLICATE KEY UPDATE
          pickup_location = VALUES(pickup_location),
          created_at = CURRENT_TIMESTAMP
      ''');

      return jsonResponse({
        'success': true,
        'message': 'Your bus RSVP has been saved.',
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not save bus RSVP',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  router.get('/bus-availability', (Request req) async {
    try {
      final date = req.url.queryParameters['date']?.trim();
      if (isBlank(date)) {
        return jsonResponse(
          {'success': false, 'message': 'Provide a ride date.'},
          statusCode: 400,
        );
      }

      final output = await runMysqlCliQuery(
        dotenv,
        '''
        SET SESSION group_concat_max_len = 100000;
        SELECT
          route_name,
          pickup_location,
          ride_time,
          DATE_FORMAT(ride_date, '%Y-%m-%d'),
          COUNT(*),
          GROUP_CONCAT(student_email ORDER BY created_at SEPARATOR ',')
        FROM bus_rsvps
        WHERE ride_date = ${sqlValue(date)}
        GROUP BY route_name, pickup_location, ride_time, ride_date
        ORDER BY route_name, ride_time, pickup_location
        ''',
      );

      final rows = parseAvailabilityRows(output);
      return jsonResponse({
        'success': true,
        'message': rows.isEmpty
            ? 'No RSVPs found for this date yet.'
            : 'Bus availability loaded.',
        'date': date,
        'items': rows,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not load bus availability',
        'error': error.toString(),
      }, statusCode: 500);
    }
  });

  router.post('/admin/publish-availability', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final date = body['rideDate']?.toString().trim();

      if (isBlank(date)) {
        return jsonResponse(
          {'success': false, 'message': 'Provide a ride date.'},
          statusCode: 400,
        );
      }

      final availabilityOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SET SESSION group_concat_max_len = 100000;
        SELECT
          route_name,
          pickup_location,
          ride_time,
          DATE_FORMAT(ride_date, '%Y-%m-%d'),
          COUNT(*),
          GROUP_CONCAT(student_email ORDER BY created_at SEPARATOR ',')
        FROM bus_rsvps
        WHERE ride_date = ${sqlValue(date)}
        GROUP BY route_name, pickup_location, ride_time, ride_date
        ORDER BY route_name, ride_time, pickup_location
        ''',
      );
      final rows = parseAvailabilityRows(availabilityOutput);

      final recipientsOutput = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT email
        FROM users
        WHERE role = 'driver'
          AND is_verified = 1
        ''',
      );
      final recipients = recipientsOutput
          .split('\n')
          .map((line) => line.trim())
          .where((email) => email.isNotEmpty)
          .toList();

      final title = 'Driver bus assignment';
      final message = buildAvailabilityMessage(rows);
      conn = await connectDB();
      final notificationTargets =
          recipients.isEmpty ? <String?>[null] : recipients;
      for (final recipient in notificationTargets) {
        await conn.query('''
          INSERT INTO admin_notifications (
            target_email,
            title,
            message,
            ride_date
          ) VALUES (
            ${recipient == null ? 'NULL' : sqlValue(recipient)},
            ${sqlValue(title)},
            ${sqlValue(message)},
            ${sqlValue(date)}
          )
        ''');
      }

      return jsonResponse({
        'success': true,
        'message': recipients.isEmpty
            ? 'Bus assignment published for drivers.'
            : 'Bus assignment sent to drivers.',
        'sentCount': recipients.length,
        'items': rows,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not publish notification',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  router.get('/notifications', (Request req) async {
    try {
      final email = req.url.queryParameters['email']?.trim().toLowerCase();
      if (isBlank(email) || !campusEmailPattern.hasMatch(email!)) {
        return jsonResponse(
          {'success': false, 'message': 'Provide a valid LuGo email.'},
          statusCode: 400,
        );
      }

      final output = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT
          title,
          message,
          IFNULL(DATE_FORMAT(ride_date, '%Y-%m-%d'), ''),
          DATE_FORMAT(created_at, '%Y-%m-%d %H:%i')
        FROM admin_notifications
        WHERE target_email = ${sqlValue(email)}
           OR target_email IS NULL
        ORDER BY created_at DESC
        LIMIT 20
        ''',
      );

      final notifications = output.trim().isEmpty
          ? <Map<String, dynamic>>[]
          : output.split('\n').map((line) {
              final parts = line.split('\t');
              return {
                'title': parts.isNotEmpty ? parts[0] : '',
                'message': parts.length > 1 ? parts[1] : '',
                'rideDate': parts.length > 2 ? parts[2] : '',
                'createdAt': parts.length > 3 ? parts[3] : '',
              };
            }).toList();

      return jsonResponse({
        'success': true,
        'message': notifications.isEmpty
            ? 'No notifications yet.'
            : 'Notifications loaded.',
        'items': notifications,
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not load notifications',
        'error': error.toString(),
      }, statusCode: 500);
    }
  });

  router.post('/driver-location', (Request req) async {
    MySqlConnection? conn;
    try {
      final body = jsonDecode(await req.readAsString());
      final driverEmail = body['driverEmail']?.toString().trim().toLowerCase();
      final routeName = body['routeName']?.toString().trim();
      final latitude = double.tryParse(body['latitude'].toString());
      final longitude = double.tryParse(body['longitude'].toString());
      final accuracy = double.tryParse(body['accuracy']?.toString() ?? '');

      if (isBlank(driverEmail) || !driverEmailPattern.hasMatch(driverEmail!)) {
        return jsonResponse(
          {'success': false, 'message': 'Use a valid driver email.'},
          statusCode: 400,
        );
      }

      if (isBlank(routeName) || latitude == null || longitude == null) {
        return jsonResponse(
          {'success': false, 'message': 'Route and GPS location are required.'},
          statusCode: 400,
        );
      }

      conn = await connectDB();
      await conn.query('''
        INSERT INTO bus_locations (
          driver_email,
          route_name,
          latitude,
          longitude,
          accuracy
        ) VALUES (
          ${sqlValue(driverEmail)},
          ${sqlValue(routeName)},
          $latitude,
          $longitude,
          ${accuracy ?? 'NULL'}
        )
        ON DUPLICATE KEY UPDATE
          latitude = VALUES(latitude),
          longitude = VALUES(longitude),
          accuracy = VALUES(accuracy),
          updated_at = CURRENT_TIMESTAMP
      ''');

      return jsonResponse({
        'success': true,
        'message': 'Live GPS shared with students.',
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not update driver location',
        'error': error.toString(),
      }, statusCode: 500);
    } finally {
      await conn?.close();
    }
  });

  router.get('/bus-location', (Request req) async {
    try {
      final routeName = req.url.queryParameters['routeName']?.trim();
      final routeFilter =
          isBlank(routeName) ? '' : 'WHERE route_name = ${sqlValue(routeName)}';

      final output = await runMysqlCliQuery(
        dotenv,
        '''
        SELECT
          driver_email,
          route_name,
          latitude,
          longitude,
          IFNULL(accuracy, ''),
          DATE_FORMAT(updated_at, '%Y-%m-%d %H:%i:%s')
        FROM bus_locations
        $routeFilter
        ORDER BY updated_at DESC
        LIMIT 1
        ''',
      );

      if (output.trim().isEmpty) {
        return jsonResponse({
          'success': false,
          'message': 'No live bus GPS has been shared yet.',
        }, statusCode: 404);
      }

      final parts = output.split('\t');
      return jsonResponse({
        'success': true,
        'message': 'Latest bus GPS loaded.',
        'item': {
          'driverEmail': parts.isNotEmpty ? parts[0] : '',
          'routeName': parts.length > 1 ? parts[1] : '',
          'latitude': parts.length > 2 ? double.tryParse(parts[2]) : null,
          'longitude': parts.length > 3 ? double.tryParse(parts[3]) : null,
          'accuracy': parts.length > 4 ? double.tryParse(parts[4]) : null,
          'updatedAt': parts.length > 5 ? parts[5] : '',
        },
      });
    } catch (error) {
      return jsonResponse({
        'success': false,
        'message': 'Could not load bus GPS',
        'error': error.toString(),
      }, statusCode: 500);
    }
  });

  // =======================
  // SERVER HANDLER
  // =======================
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final port = int.tryParse(dotenv['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print(
      '🚀 LuGo Server running on http://${server.address.host}:${server.port}');
}
