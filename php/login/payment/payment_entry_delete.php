<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $payment_id = mysqli_real_escape_string($conn, $_POST['payment_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($payment_id) || empty($companyid)) {
        throw new Exception("Required fields are missing");
    }

    // Delete payment entry
    $sql = "DELETE FROM payment_entry WHERE id = '$payment_id' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        if (mysqli_affected_rows($conn) > 0) {
            $response["status"] = "success";
            $response["message"] = "Payment entry deleted successfully";
        } else {
            $response["message"] = "Payment entry not found";
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