<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    $sql = "SELECT id, companyid, ledgername, groupname, opening, type 
            FROM acledger 
            WHERE companyid = '$companyid' 
           
            ORDER BY ledgername";
    // AND (groupname = 'Cash-in-hand' OR groupname = 'Bank Accounts') 
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $accounts = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $accounts[] = $row;
        }
        $response["status"] = "success";
        $response["accounts"] = $accounts;
    } else {
        $response["message"] = "Error: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>