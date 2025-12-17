<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Initialize response array
$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    // Get POST data
    $customerid = $_POST['customerid'] ?? '';
    $companyid = $_POST['companyid'] ?? '';

    // Validate required fields
    if (empty($customerid) || empty($companyid)) {
        throw new Exception("Missing required fields");
    }

    // Prepare SQL statement - FIXED: added FROM keyword
    $sql = "DELETE FROM customermaster WHERE id = ? AND companyid = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("ss", $customerid, $companyid);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            $response["status"] = "success";
            $response["message"] = "Customer deleted successfully";
        } else {
            $response["message"] = "No customer found with the given ID";
        }
    } else {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

// Output JSON response
echo json_encode($response);

// Close connection
if (isset($conn) && $conn) {
    $conn->close();
}
exit(); // Ensure no further output
?>