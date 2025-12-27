<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "", "next_serial" => "RCP-0001"];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($companyid)) {
        throw new Exception("Company ID is required");
    }

    // Get last serial number
    $sql = "SELECT serial_no FROM receipt_entry WHERE companyid = '$companyid' ORDER BY id DESC LIMIT 1";
    $result = mysqli_query($conn, $sql);
    
    if (mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        $last_serial = $row['serial_no'];
        
        // Extract number from RCP-0001 format
        if (preg_match('/RCP-(\d+)/', $last_serial, $matches)) {
            $last_number = intval($matches[1]);
            $next_number = $last_number + 1;
            $response["next_serial"] = "RCP-" . str_pad($next_number, 4, "0", STR_PAD_LEFT);
        } else {
            // If format is wrong, start from 1
            $response["next_serial"] = "RCP-0001";
        }
    } else {
        // No records yet, start with RCP-0001
        $response["next_serial"] = "RCP-0001";
    }
    
    $response["status"] = "success";
    $response["message"] = "Next serial generated successfully";

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
if ($conn) {
    mysqli_close($conn);
}
?>