<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$stats = [];

$conn->prepare("SELECT COUNT(*) AS total FROM products")->execute();
$stats['total_products'] = (int) $conn->query("SELECT COUNT(*) FROM products")->fetchColumn();

$stats['total_categories'] = (int) $conn->query("SELECT COUNT(*) FROM categories")->fetchColumn();

$stats['total_users'] = (int) $conn->query("SELECT COUNT(*) FROM users WHERE role = 'customer'")->fetchColumn();

$stats['total_orders'] = (int) $conn->query("SELECT COUNT(*) FROM orders")->fetchColumn();

$stats['total_revenue'] = (float) $conn->query("SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status != 'cancelled'")->fetchColumn();

$stats['pending_orders'] = (int) $conn->query("SELECT COUNT(*) FROM orders WHERE status = 'pending'")->fetchColumn();

$stats['delivered_orders'] = (int) $conn->query("SELECT COUNT(*) FROM orders WHERE status = 'delivered'")->fetchColumn();

// Recent 5 orders
$stmt = $conn->prepare(
    "SELECT o.id, o.total_amount, o.status, o.created_at, u.name AS customer_name
     FROM orders o JOIN users u ON o.user_id = u.id
     ORDER BY o.created_at DESC LIMIT 5"
);
$stmt->execute();
$stats['recent_orders'] = $stmt->fetchAll();

echo json_encode(['success' => true, 'data' => $stats]);
