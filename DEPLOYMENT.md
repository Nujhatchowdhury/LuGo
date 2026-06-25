# LuGo Deployment

This app has two parts:

- `backend/lugo_backend`: Dart API server, MySQL, OTP email, RSVP, GPS, admin/driver data.
- `frontend/lugo_app`: Flutter Android/iOS/web app.

## Backend Online Setup

Deploy `backend/lugo_backend` to any Docker-capable host.

Set these environment variables on the host:

```env
PORT=8080
DB_HOST=your-online-mysql-host
DB_PORT=3306
DB_USER=your-mysql-user
DB_PASSWORD=your-mysql-password
DB_NAME=lugo_bus
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-sender-gmail
SMTP_PASSWORD=your-gmail-app-password
SMTP_FROM=your-sender-gmail
SMTP_FROM_NAME=LuGo Bus
SMTP_SSL=false
SMTP_ALLOW_INSECURE=false
```

Important: the backend must use an online MySQL database if the mobile app should work without your Mac.

## Build App With Online Backend

After the backend is online, copy its HTTPS URL and build the app with `API_BASE_URL`.

Android:

```bash
cd /Users/najifanujhat/Downloads/lugo_project/frontend/lugo_app
flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-url
```

iPhone release:

```bash
cd /Users/najifanujhat/Downloads/lugo_project/frontend/lugo_app
flutter build ios --release --dart-define=API_BASE_URL=https://your-backend-url
```

Local testing still works without `API_BASE_URL`:

- Web and macOS use `http://localhost:8080`.
- Android emulator uses `http://10.0.2.2:8080`.
- iPhone local debug currently uses your Mac WiFi IP fallback.

## Why This Matters

If the app is built with only `localhost` or your Mac WiFi IP, login works only while your Mac backend is running and the phone is on the same WiFi.

If the app is built with a hosted `API_BASE_URL`, login, OTP, RSVP, GPS, admin, and driver screens can work from anywhere with internet.
