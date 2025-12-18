<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $fromdate = isset($_POST['fromdate']) ? mysqli_real_escape_string($conn, $_POST['fromdate']) : '';
    $todate = isset($_POST['todate']) ? mysqli_real_escape_string($conn, $_POST['todate']) : '';
    
    // Build query
    $sql = "SELECT 
            c.*,
            l.loanno,
            l.loanamount,
            cu.customername,
            cu.mobile1
            FROM collectionmaster c
            LEFT JOIN loanmaster l ON c.loanid = l.id
            LEFT JOIN customermaster cu ON l.customerid = cu.id
            WHERE c.companyid = '$companyid'";
    
    // Add date filters if provided
    if (!empty($fromdate) && !empty($todate)) {
        $sql .= " AND c.collectiondate BETWEEN '$fromdate' AND '$todate'";
    }
    
    $sql .= " ORDER BY c.collectiondate DESC, c.id DESC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Error fetching collections: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $collections = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $collections[] = $row;
    }
    
    $response["status"] = "success";
    $response["message"] = "Collections fetched successfully";
    $response["collections"] = $collections;
    $response["count"] = count($collections);

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>