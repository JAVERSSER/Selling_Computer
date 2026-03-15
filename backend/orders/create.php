<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$data             = json_decode(file_get_contents('php://input'), true);
$user_id          = $data['user_id']          ?? 0;
$total_amount     = $data['total_amount']     ?? 0;
$shipping_address = $data['shipping_address'] ?? '';
$items            = $data['items']            ?? [];

if (!$user_id || !$shipping_address || empty($items)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

try {
    $conn->beginTransaction();

    $conn->prepare(
        "INSERT INTO orders (user_id, total_amount, shipping_address) VALUES (?, ?, ?)"
    )->execute([$user_id, $total_amount, $shipping_address]);
    $order_id = $conn->lastInsertId();

    $itemStmt = $conn->prepare(
        "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)"
    );
    foreach ($items as $item) {
        $itemStmt->execute([$order_id, $item['product_id'], $item['quantity'], $item['price']]);
        $conn->prepare("UPDATE products SET stock = stock - ? WHERE id = ?")
             ->execute([$item['quantity'], $item['product_id']]);
    }

    $conn->prepare("DELETE FROM cart WHERE user_id = ?")->execute([$user_id]);

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Order placed successfully', 'order_id' => $order_id]);
} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
