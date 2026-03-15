<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$data     = json_decode(file_get_contents('php://input'), true);
$id       = $data['id']       ?? 0;
$quantity = $data['quantity'] ?? 1;

$conn->prepare("UPDATE cart SET quantity = ? WHERE id = ?")->execute([$quantity, $id]);

echo json_encode(['success' => true, 'message' => 'Cart updated']);
