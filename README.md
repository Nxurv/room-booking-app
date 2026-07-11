# Room Booking App — How to Run It

Everything from the brief is implemented:
- MySQL: `users`, `rooms`, `bookings` tables
- Backend: Express API with JWT auth, admin-only room routes, and a
  race-condition-safe booking endpoint
- Flutter: Login/Register, Admin room list + add/edit form, Customer room
  list with Book button

## 1. Set up MySQL

```bash
mysql -u root -p < backend/schema.sql
```

This creates the `room_booking` database and the 3 tables.

## 2. Set up the backend

```bash
cd backend
npm install
cp .env.example .env
```

Open `.env` and set `DB_PASSWORD` to your real MySQL password. Then create
the admin account (this reads `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `.env`):

```bash
npm run seed
```

Start the server:

```bash
npm start
```

You should see `Server running on http://localhost:3000`.

### Test in Postman (do this before touching Flutter)

1. `POST http://localhost:3000/auth/login` with body
   `{ "email": "admin@hotel.com", "password": "admin123" }` → copy the `token`.
2. `POST http://localhost:3000/rooms` with header `Authorization: Bearer <token>`
   and body `{ "name": "Room 101", "price": 50 }`.
3. `GET http://localhost:3000/rooms` → should list the room as `available`.
4. `POST http://localhost:3000/auth/register` to create a customer, then
   `POST /auth/login` as that customer to get a customer token.
5. `POST http://localhost:3000/bookings` as the customer with
   `{ "room_id": 1 }` → should succeed (`201`).
6. Run the exact same request again → should fail with
   `400 { "error": "Room is already occupied" }`. **This is the core rule the
   assignment is testing, and it's enforced with a database transaction
   (`SELECT ... FOR UPDATE`), so it holds even if two requests arrive at the
   same instant.**

## 3. Set up Flutter

```bash
cd ../flutter_app
flutter pub get
```

Open `lib/api_service.dart` and check the `baseUrl`:
- Android emulator → keep `http://10.0.2.2:3000` (this is how the emulator
  reaches your computer's `localhost`)
- Real phone on the same WiFi → change it to your computer's LAN IP, e.g.
  `http://192.168.1.20:3000`
- iOS simulator → `http://localhost:3000` works directly

Run it:

```bash
flutter run
```

## 4. Test the full flow

1. Log in as admin (`admin@hotel.com` / `admin123`) → add a room.
2. Log out, register a new customer, log in as that customer → the room
   shows as **Available** with a **Book** button.
3. Tap **Book** → it turns **Occupied**.
4. **The most important test**: register a second customer account, log in
   with it, and try to book the same room. You should see a red error
   message ("Room is already occupied"), not a silent failure or a crash.

## Project structure

```
backend/
  server.js          entry point
  db.js              MySQL connection pool
  seed.js            creates the fixed admin account
  schema.sql         the 3 tables
  middleware/auth.js JWT check + admin check
  routes/auth.js     register, login
  routes/rooms.js    add, list, edit rooms
  routes/bookings.js book a room (the critical endpoint)

flutter_app/
  lib/main.dart                       app entry, routes based on saved session
  lib/api_service.dart                all HTTP calls + session storage
  lib/login_screen.dart
  lib/register_screen.dart
  lib/admin_room_list_screen.dart
  lib/admin_room_form_screen.dart     used for both Add and Edit
  lib/customer_room_list_screen.dart
```

## Why double-booking can't happen

`POST /bookings` opens a database transaction and runs
`SELECT status FROM rooms WHERE id = ? FOR UPDATE`. That `FOR UPDATE` locks
the row, so if two customers tap "Book" on the same room at the same
millisecond, the second request has to wait for the first transaction to
finish. By the time it gets the lock, the room is already `occupied`, so it
is correctly rejected. This is the backend-enforced check the brief requires
— the Flutter UI never decides this on its own.
