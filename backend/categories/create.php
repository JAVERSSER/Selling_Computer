<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$data = json_decode(file_get_contents('php://input'), true);
$name = trim($data['name'] ?? '');

if (!$name) {
    echo json_encode(['success' => false, 'message' => 'Category name required']);
    exit();
}

$conn->prepare("INSERT INTO categories (name) VALUES (?)")->execute([$name]);

echo json_encode(['success' => true, 'message' => 'Category created', 'id' => $conn->lastInsertId()]);
