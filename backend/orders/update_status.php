<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$data   = json_decode(file_get_contents('php://input'), true);
$id     = $data['id']     ?? 0;
$status = $data['status'] ?? '';

$allowed = ['pending', 'preparing', 'shipping', 'delivered'];
if (!in_array($status, $allowed)) {
    echo json_encode(['success' => false, 'message' => 'Invalid status']);
    exit();
}

$conn->prepare("UPDATE orders SET status = ? WHERE id = ?")->execute([$status, $id]);

echo json_encode(['success' => true, 'message' => 'Order status updated']);
