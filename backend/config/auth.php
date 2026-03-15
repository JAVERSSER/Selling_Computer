<?php
define('JWT_SECRET', 'pcstore_secret_2024');

function generateToken($userId) {
    $header  = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64_encode(json_encode([
        'user_id' => $userId,
        'exp'     => time() + (86400 * 7),
    ]));
    $sig = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$sig";
}

function verifyToken($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$header, $payload, $sig] = $parts;
    $expected = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    if (!hash_equals($expected, $sig)) return false;
    $data = json_decode(base64_decode($payload), true);
    if (!$data || $data['exp'] < time()) return false;
    return $data['user_id'];
}

function getAuthUser($conn) {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (!str_starts_with($auth, 'Bearer ')) return null;
    $token  = substr($auth, 7);
    $userId = verifyToken($token);
    if (!$userId) return null;
    $stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function requireAdmin($conn) {
    $user = getAuthUser($conn);
    if (!$user || $user['role'] !== 'admin') {
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        exit();
    }
    return $user;
}

function requireAuth($conn) {
    $user = getAuthUser($conn);
    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Please login']);
        exit();
    }
    return $user;
}
