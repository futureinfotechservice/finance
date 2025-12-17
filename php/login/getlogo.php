<?php
include 'conn.php'; // DB connection

// Allow CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Get companyid from query string
$companyid = isset($_GET['companyid']) ? intval($_GET['companyid']) : 0;

if ($companyid <= 0) {
    http_response_code(400);
    echo "Invalid companyid";
    exit;
}

// Fetch image URL from database
$sql = "SELECT logourl FROM companymaster WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $companyid);
$stmt->execute();
$stmt->bind_result($logourl);
$stmt->fetch();
$stmt->close();

if (!$logourl) {
    http_response_code(404);
    echo "No logo found";
    exit;
}

// Get file extension from URL
$ext = pathinfo(parse_url($logourl, PHP_URL_PATH), PATHINFO_EXTENSION);

// Set proper content-type
switch (strtolower($ext)) {
    case 'jpg': case 'jpeg':
        header("Content-Type: image/jpeg");
        break;
    case 'png':
        header("Content-Type: image/png");
        break;
    case 'gif':
        header("Content-Type: image/gif");
        break;
    default:
        header("Content-Type: application/octet-stream");
}

// Stream the remote image to the client
$ch = curl_init($logourl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$imageData = curl_exec($ch);
curl_close($ch);

if ($imageData) {
    echo $imageData;
} else {
    http_response_code(404);
    echo "Image not found";
}
