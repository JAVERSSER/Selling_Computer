<?php
require_once '../config/db.php';

$db   = new Database();
$conn = $db->connect();

$data = json_decode(file_get_contents('php://input'), true);

if (empty($data['name']) || empty($data['email']) || empty($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Name, email and password are required']);
    exit();
}

$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->execute([trim($data['email'])]);
if ($stmt->fetch()) {
    echo json_encode(['success' => false, 'message' => 'Email already registered']);
    exit();
}

$hash = password_hash($data['password'], PASSWORD_BCRYPT);
$stmt = $conn->prepare(
    "INSERT INTO users (name, email, password, phone, address) VALUES (?, ?, ?, ?, ?)"
);
$stmt->execute([
    trim($data['name']),
    trim($data['email']),
    $hash,
    $data['phone'] ?? null,
    $data['address'] ?? null,
]);

echo json_encode(['success' => true, 'message' => 'Account created successfully']);
