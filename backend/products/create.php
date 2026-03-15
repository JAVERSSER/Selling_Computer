<?php
@ini_set('upload_max_filesize', '10M');
@ini_set('post_max_size', '12M');
@ini_set('memory_limit', '256M');

require_once '../config/db.php';
require_once '../config/auth.php';

$db   = new Database();
$conn = $db->connect();

requireAdmin($conn);

$name        = trim($_POST['name']        ?? '');
$description = trim($_POST['description'] ?? '');
$price       = $_POST['price']            ?? 0;
$stock       = $_POST['stock']            ?? 0;
$category_id = $_POST['category_id']      ?? null;

if (!$name || !$price) {
    echo json_encode(['success' => false, 'message' => 'Name and price are required']);
    exit();
}

$imageData = null;
if (!empty($_FILES['image']['tmp_name']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
    $bytes = file_get_contents($_FILES['image']['tmp_name']);
    if ($bytes !== false) {
        $ext     = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
        $mimeMap = ['jpg'  => 'image/jpeg', 'jpeg' => 'image/jpeg',
                    'png'  => 'image/png',  'gif'  => 'image/gif',
                    'webp' => 'image/webp'];
        $mime      = $mimeMap[$ext] ?? (mime_content_type($_FILES['image']['tmp_name']) ?: 'image/png');
        $imageData = 'data:' . $mime . ';base64,' . base64_encode($bytes);
    }
}

$stmt = $conn->prepare(
    "INSERT INTO products (name, description, price, stock, category_id, image)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->execute([$name, $description, $price, $stock, $category_id ?: null, $imageData]);

echo json_encode([
    'success'   => true,
    'message'   => 'Product created',
    'id'        => $conn->lastInsertId(),
    'has_image' => $imageData !== null,
]);
