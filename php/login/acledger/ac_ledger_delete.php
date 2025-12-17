<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $ledgerid = mysqli_real_escape_string($conn, $_POST['ledgerid'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($ledgerid) || empty($companyid)) {
        throw new Exception("Required fields are missing");
    }

    $sql = "DELETE FROM acledger WHERE id = '$ledgerid' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        if (mysqli_affected_rows($conn) > 0) {
            $response["status"] = "success";
            $response["message"] = "Ledger deleted successfully";
        } else {
            throw new Exception("Ledger not found");
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