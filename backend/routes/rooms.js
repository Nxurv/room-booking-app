const express = require('express');
const pool = require('../db');
const { verifyToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /rooms -> everyone (must be logged in, any role)
router.get('/', verifyToken, async (req, res) => {
  try {
    const [rooms] = await pool.query('SELECT id, name, price, status FROM rooms ORDER BY id');
    res.json(rooms);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /rooms -> admin only
router.post('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { name, price, status } = req.body;
    if (!name || price === undefined) {
      return res.status(400).json({ error: 'name and price are required' });
    }
    const roomStatus = status === 'occupied' ? 'occupied' : 'available';

    const [result] = await pool.query(
      'INSERT INTO rooms (name, price, status) VALUES (?, ?, ?)',
      [name, price, roomStatus]
    );
    res.status(201).json({ id: result.insertId, name, price, status: roomStatus });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /rooms/:id -> admin only
router.put('/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, status } = req.body;

    const [existing] = await pool.query('SELECT * FROM rooms WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Room not found' });
    }
    const room = existing[0];

    const newName = name !== undefined ? name : room.name;
    const newPrice = price !== undefined ? price : room.price;
    const newStatus = status !== undefined ? status : room.status;

    await pool.query(
      'UPDATE rooms SET name = ?, price = ?, status = ? WHERE id = ?',
      [newName, newPrice, newStatus, id]
    );

    res.json({ id: Number(id), name: newName, price: newPrice, status: newStatus });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
