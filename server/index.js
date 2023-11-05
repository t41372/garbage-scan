const express = require('express');
const sqlite3 = require('sqlite3').verbose();

const app = express();
app.use(express.json());

// 创建 SQLite 数据库
const db = new sqlite3.Database('database.db', (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log('Connected to the SQLite database.');
        // 创建数据表（如果不存在）
        db.run('CREATE TABLE IF NOT EXISTS data (id INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT, value TEXT)');
    }
});

// API 接收数据并存储到数据库
app.post('/api/data', (req, res) => {
    const { key, value } = req.body;
    if (!key || !value) {
        return res.status(400).json({ error: 'Please provide both key and value.' });
    }

    db.run('INSERT INTO data (key, value) VALUES (?, ?)', [key, value], function (err) {
        if (err) {
            return res.status(500).json({ error: err.message });
        }

        res.status(201).json({ message: 'Data added to the database' });
    });
});

// 从数据库中读取数据的 API
app.get('/api/data', (req, res) => {
    db.all('SELECT * FROM data', [], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json({ data: rows });
    });
});

// 设置端口并启动服务器
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
