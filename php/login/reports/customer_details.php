<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid']) || !isset($_POST['customerid'])) {
        $response["message"] = "Company ID and Customer ID are required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $customerId = mysqli_real_escape_string($conn, $_POST['customerid']);

    $sql = "SELECT * FROM customermaster 
            WHERE id = '$customerId' AND companyid = '$companyid' 
            LIMIT 1";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    if (mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        $response["status"] = "success";
        $response["message"] = "Customer details fetched successfully";
        $response["customer"] = $row;
    } else {
        $response["message"] = "Customer not found";
    }

} catch (Exception $e) {
    error_log("Exception in customer_details.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>