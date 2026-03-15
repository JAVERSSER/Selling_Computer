<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$data       = json_decode(file_get_contents('php://input'), true);
$user_id    = $data['user_id']    ?? 0;
$product_id = $data['product_id'] ?? 0;
$quantity   = $data['quantity']   ?? 1;

if (!$user_id || !$product_id) {
    echo json_encode(['success' => false, 'message' => 'user_id and product_id required']);
    exit();
}

// If already in cart, increase quantity
$stmt = $conn->prepare("SELECT id, quantity FROM cart WHERE user_id = ? AND product_id = ?");
$stmt->execute([$user_id, $product_id]);
$existing = $stmt->fetch();

if ($existing) {
    $conn->prepare("UPDATE cart SET quantity = ? WHERE id = ?")
         ->execute([$existing['quantity'] + $quantity, $existing['id']]);
} else {
    $conn->prepare("INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)")
         ->execute([$user_id, $product_id, $quantity]);
}

echo json_encode(['success' => true, 'message' => 'Added to cart']);
