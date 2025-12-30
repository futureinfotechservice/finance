<?php
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

    $sql = "SELECT id, customername, mobile1, mobile2, refer, refercontact, 
                   spousename, spousecontact, photourl 
            FROM customermaster 
            WHERE companyid = '$companyid' 
            AND activestatus = '1'
            ORDER BY customername ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $customers = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $customers[] = $row;
    }
    
    $response["status"] = "success";
    $response["message"] = "Customers fetched successfully";
    $response["customers"] = $customers;

} catch (Exception $e) {
    error_log("Exception in fetch_all_customers.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>