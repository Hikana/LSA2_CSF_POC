<?php
$db = new SQLite3('/var/www/html/users.db');
$db->exec("DROP TABLE IF EXISTS users");
$db->exec("CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)");
$db->exec("INSERT INTO users (username, password) VALUES ('admin', 'adminpass')");
echo "✅ users.db 已建立並插入 admin 資料";
