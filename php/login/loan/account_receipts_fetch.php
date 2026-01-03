<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $account_id = mysqli_real_escape_string($conn, $_POST['account_id']);
    
    $sql = "SELECT amount FROM receipt_entry 
            WHERE companyid = '$companyid' 
            AND receipt_from_id = '$account_id'";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $receipts = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $receipts[] = $row;
        }
        $response["status"] = "success";
        $response["receipts"] = $receipts;
    } else {
        $response["message"] = "Error: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>