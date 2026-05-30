import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> main() async {
  final dotenv = DotEnv(includePlatformEnvironment: true)..load();

  final smtpServer = SmtpServer(
    dotenv['SMTP_HOST']!,
    port: int.tryParse(dotenv['SMTP_PORT'] ?? '') ?? 587,
    username: dotenv['SMTP_USERNAME'],
    password: dotenv['SMTP_PASSWORD'],
    ssl: (dotenv['SMTP_SSL'] ?? '').toLowerCase() == 'true',
    allowInsecure:
        (dotenv['SMTP_ALLOW_INSECURE'] ?? '').toLowerCase() == 'true',
  );

  final recipient = dotenv['SMTP_FROM']!;

  final message = Message()
    ..from = Address(
      dotenv['SMTP_FROM']!,
      dotenv['SMTP_FROM_NAME'] ?? 'LuGo Bus',
    )
    ..recipients.add(recipient)
    ..subject = 'LuGo OTP email test'
    ..text = 'This is a test email from your LuGo backend SMTP setup.';

  final sendReport = await send(message, smtpServer);
  print('Email sent: ${sendReport.toString()}');
}
