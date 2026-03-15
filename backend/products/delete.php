<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$id = $_GET['id'] ?? 0;
if (!$id) {
    echo json_encode(['success' => false, 'message' => 'Product ID required']);
    exit();
}

$stmt = $conn->prepare("SELECT image FROM products WHERE id = ?");
$stmt->execute([$id]);
$product = $stmt->fetch();
if ($product && $product['image']) {
    $path = '../uploads/' . $product['image'];
    if (file_exists($path)) unlink($path);
}

$conn->prepare("DELETE FROM products WHERE id = ?")->execute([$id]);

echo json_encode(['success' => true, 'message' => 'Product deleted']);
