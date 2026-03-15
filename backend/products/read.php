<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$category_id = $_GET['category_id'] ?? null;
$search      = $_GET['search']      ?? null;

$sql    = "SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE 1=1";
$params = [];

if ($category_id) {
    $sql     .= " AND p.category_id = ?";
    $params[] = $category_id;
}
if ($search) {
    $sql     .= " AND (p.name LIKE ? OR p.description LIKE ?)";
    $params[] = "%$search%";
    $params[] = "%$search%";
}

$sql .= " ORDER BY p.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->execute($params);

echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
