<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$response = ["status" => "error", "message" => "Unknown error", "collectionno" => ""];

try {
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $prefix = 'COL';
    
    // Get last collection number
    $sql = "SELECT collectionno FROM collectionmaster 
            WHERE companyid = '$companyid' 
            AND collectionno LIKE '$prefix%'
            ORDER BY id DESC 
            LIMIT 1";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result && mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        $lastCollectionNo = $row['collectionno'];
        
        // Extract numeric part (e.g., COL00001 -> 1)
        if (preg_match('/\d+/', $lastCollectionNo, $matches)) {
            $lastNumber = (int)$matches[0];
            $newNumber = $lastNumber + 1;
        } else {
            $newNumber = 1;
        }
    } else {
        // No existing collections, start from 1
        $newNumber = 1;
    }
    
    // Format with leading zeros (5 digits)
    $formattedNumber = str_pad($newNumber, 5, '0', STR_PAD_LEFT);
    $newCollectionNo = $prefix . $formattedNumber;
    
    $response["status"] = "success";
    $response["message"] = "Collection number generated successfully";
    $response["collectionno"] = $newCollectionNo;

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
    // Generate fallback number
    $response["collectionno"] = 'COL' . date('Ymd') . rand(100, 999);
}

echo json_encode($response);
mysqli_close($conn);
?>