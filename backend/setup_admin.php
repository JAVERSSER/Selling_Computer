<?php
require_once 'config/db.php';

$db   = new Database();
$conn = $db->connect();

$name     = 'Admin';
$email    = 'admin@pcstore.com';
$password = 'admin123';
$hash     = password_hash($password, PASSWORD_BCRYPT);

// Remove existing admin if any, then insert fresh
$conn->prepare("DELETE FROM users WHERE email = ?")->execute([$email]);
$stmt = $conn->prepare(
    "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'admin')"
);
$stmt->execute([$name, $email, $hash]);

echo json_encode([
    'success' => true,
    'message' => 'Admin account created',
    'email'   => $email,
    'password'=> $password,
]);
