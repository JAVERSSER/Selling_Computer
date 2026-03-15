<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$id = $_GET['id'] ?? 0;
$conn->prepare("DELETE FROM cart WHERE id = ?")->execute([$id]);

echo json_encode(['success' => true, 'message' => 'Item removed from cart']);
