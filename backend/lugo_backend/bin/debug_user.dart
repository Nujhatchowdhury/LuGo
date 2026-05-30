import 'package:dotenv/dotenv.dart';
import 'package:mysql1/mysql1.dart';

Future<void> main() async {
  final dotenv = DotEnv(includePlatformEnvironment: true)..load();

  final conn = await MySqlConnection.connect(
    ConnectionSettings(
      host: dotenv['DB_HOST'] ?? '127.0.0.1',
      port: int.tryParse(dotenv['DB_PORT'] ?? '') ?? 3306,
      user: dotenv['DB_USER'] ?? 'root',
      password: dotenv['DB_PASSWORD'] ?? '',
      db: dotenv['DB_NAME'] ?? 'lugo_bus',
    ),
  );

  final rows = await conn.query('SELECT * FROM users');
  final countRows = await conn.query('SELECT COUNT(*) AS total FROM users');

  print('all users length: ${rows.length}');

  for (final row in countRows) {
    print({'total': row[0], 'totalNamed': row['total']});
  }

  for (final row in rows) {
    print({
      'email': row['email'],
      'password': row['password'],
      'otp': row['otp'],
      'is_verified': row['is_verified'],
      'role': row['role'],
    });
  }

  await conn.close();
}
