<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$stmt = $conn->prepare("SELECT * FROM categories ORDER BY name ASC");
$stmt->execute();

echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
