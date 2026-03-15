<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$stmt = $conn->prepare(
    "SELECT id, name, email, role, phone, address, created_at FROM users ORDER BY created_at DESC"
);
$stmt->execute();

echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
