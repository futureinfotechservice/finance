<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $account_id = mysqli_real_escape_string($conn, $_POST['account_id']);
    
    $sql = "SELECT opening FROM acledger 
            WHERE companyid = '$companyid' 
            AND id = '$account_id'";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result && mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        $response["status"] = "success";
        $response["opening"] = $row['opening'];
    } else {
        $response["message"] = "Account not found";
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>