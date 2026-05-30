router.post('/login', (Request req) async {
  final body = jsonDecode(await req.readAsString());

  final conn = await connectDB();

  final result = await conn.query(
    'SELECT * FROM users WHERE email = ? AND password = ? AND is_verified = ?',
    [body['email'], body['password'], true],
  );

  if (result.isEmpty) {
    await conn.close();
    return Response.forbidden(
      jsonEncode({'message': 'Login failed'}),
    );
  }

  final user = result.first;

  // JWT TOKEN CREATE
  final jwt = JWT({
    'id': user['id'],
    'email': user['email'],
    'role': user['role'],
  });

  final token = jwt.sign(SecretKey('lugo_secret_key'));

  await conn.close();

  return Response.ok(
    jsonEncode({
      'message': 'Login success',
      'token': token,
      'role': user['role']
    }),
  );
});