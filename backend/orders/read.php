<?php
require_once '../config/db.php';

$db      = new Database();
$conn    = $db->connect();
$user_id = $_GET['user_id'] ?? null;

if ($user_id) {
    $stmt = $conn->prepare(
        "SELECT o.*, u.name AS customer_name FROM orders o
         JOIN users u ON o.user_id = u.id
         WHERE o.user_id = ? ORDER BY o.created_at DESC"
    );
    $stmt->execute([$user_id]);
} else {
    $stmt = $conn->prepare(
        "SELECT o.*, u.name AS customer_name FROM orders o
         JOIN users u ON o.user_id = u.id
         ORDER BY o.created_at DESC"
    );
    $stmt->execute();
}

$orders = $stmt->fetchAll();

foreach ($orders as &$order) {
    $s = $conn->prepare(
        "SELECT oi.*, p.name AS product_name, p.image FROM order_items oi
         JOIN products p ON oi.product_id = p.id
         WHERE oi.order_id = ?"
    );
    $s->execute([$order['id']]);
    $order['items'] = $s->fetchAll();
}

echo json_encode(['success' => true, 'data' => $orders]);
