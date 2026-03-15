<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$host = '127.0.0.1';
$port = 4306;

$fp = @fsockopen($host, $port, $errno, $errstr, 3);
if ($fp) {
    fclose($fp);
    $mysql = "OPEN";
} else {
    $mysql = "CLOSED - Start MySQL in XAMPP (port $port)";
}

echo json_encode([
    'php'        => phpversion(),
    'mysql_port' => $mysql,
    'time'       => date('Y-m-d H:i:s'),
]);
