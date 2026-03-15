<?php
require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

$data = json_decode(file_get_contents('php://input'), true);

if (empty($data['email']) || empty($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Email and password are required']);
    exit();
}

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([trim($data['email'])]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user || !password_verify($data['password'], $user['password'])) {
    echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
    exit();
}

$token = generateToken($user['id']);
unset($user['password']);

echo json_encode([
    'success' => true,
    'token'   => $token,
    'user'    => $user,
]);
