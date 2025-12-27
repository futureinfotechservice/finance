<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $receipt_id = mysqli_real_escape_string($conn, $_POST['receipt_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($receipt_id) || empty($companyid)) {
        throw new Exception("Required fields are missing");
    }

    // Delete receipt entry
    $sql = "DELETE FROM receipt_entry WHERE id = '$receipt_id' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        if (mysqli_affected_rows($conn) > 0) {
            $response["status"] = "success";
            $response["message"] = "Receipt entry deleted successfully";
        } else {
            $response["message"] = "Receipt entry not found";
        }
    } else {
        throw new Exception("Database error: " . mysqli_error($conn));
    }

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
if ($conn) {
    mysqli_close($conn);
}
?>