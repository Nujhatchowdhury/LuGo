LuGo backend API.

Create a `.env` file in this folder based on `.env.example` and set your real
MySQL credentials before running the server.

To enable real OTP email delivery, also set the SMTP values in `.env`.
For iCloud Mail, use an app-specific password with `smtp.mail.me.com` on port
`587`.

If your database is missing the `users` table or the new `role` column, run:

`database/lugo_bus.sql`
