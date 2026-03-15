<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$id = $_GET['id'] ?? 0;
$conn->prepare("DELETE FROM categories WHERE id = ?")->execute([$id]);

echo json_encode(['success' => true, 'message' => 'Category deleted']);
