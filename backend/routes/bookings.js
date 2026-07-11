const express = require('express');
const pool = require('../db');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// POST /bookings -> customer books a room
// This is THE important endpoint: it must be impossible for two
// simultaneous requests to both succeed on the same room.
router.post('/', verifyToken, async (req, res) => {
  const { room_id } = req.body;
  if (!room_id) {
    return res.status(400).json({ error: 'room_id is required' });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Lock the row so no other transaction can read/change it until we commit.
    const [rows] = await connection.query(
      'SELECT id, status FROM rooms WHERE id = ? FOR UPDATE',
      [room_id]
    );

    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: 'Room not found' });
    }

    if (rows[0].status !== 'available') {
      await connection.rollback();
      return res.status(400).json({ error: 'Room is already occupied' });
    }

    // Flip the room to occupied and create the booking, atomically.
    await connection.query('UPDATE rooms SET status = ? WHERE id = ?', ['occupied', room_id]);
    const [result] = await connection.query(
      'INSERT INTO bookings (room_id, customer_id) VALUES (?, ?)',
      [room_id, req.user.id]
    );

    await connection.commit();

    res.status(201).json({
      booking_id: result.insertId,
      room_id: Number(room_id),
      status: 'occupied',
      message: 'Booking confirmed',
    });
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    connection.release();
  }
});

module.exports = router;
