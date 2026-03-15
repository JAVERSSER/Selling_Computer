<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$id = $_GET['id'] ?? 0;

$stmt = $conn->prepare(
    "SELECT p.*, c.name AS category_name FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     WHERE p.id = ?"
);
$stmt->execute([$id]);
$product = $stmt->fetch();

if ($product) {
    echo json_encode(['success' => true, 'data' => $product]);
} else {
    echo json_encode(['success' => false, 'message' => 'Product not found']);
}
