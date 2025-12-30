<?php
// get_ledgers.php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    $sql = "SELECT 
                id,
                ledgername as ledgerName,
                groupname as groupName,
                opening
            FROM acledger 
            WHERE companyid = '$companyid'
            ORDER BY ledgername ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $ledgers = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $ledgers[] = $row;
    }
    
    $response["status"] = "success";
    $response["message"] = "Ledgers fetched successfully";
    $response["ledgers"] = $ledgers;
    
} catch (Exception $e) {
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>