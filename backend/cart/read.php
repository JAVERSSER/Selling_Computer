<?php
require_once '../config/db.php';

$db      = new Database();
$conn    = $db->connect();
$user_id = $_GET['user_id'] ?? 0;

$stmt = $conn->prepare(
    "SELECT c.id, c.product_id, c.quantity,
            p.name AS product_name, p.price, p.image, p.stock
     FROM cart c
     JOIN products p ON c.product_id = p.id
     WHERE c.user_id = ?"
);
$stmt->execute([$user_id]);

echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
