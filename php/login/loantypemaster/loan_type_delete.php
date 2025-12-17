<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $loantypeid = mysqli_real_escape_string($conn, $_POST['loantypeid'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($loantypeid) || empty($companyid)) {
        throw new Exception("Required fields are missing");
    }

    // Check if loan type is being used in loans table (optional)
    // $checkSql = "SELECT * FROM loans WHERE loantypeid = '$loantypeid'";
    // $result = mysqli_query($conn, $checkSql);
    // if (mysqli_num_rows($result) > 0) {
    //     throw new Exception("Cannot delete: Loan type is in use");
    // }

    $sql = "DELETE FROM loantypemaster WHERE id = '$loantypeid' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        if (mysqli_affected_rows($conn) > 0) {
            $response["status"] = "success";
            $response["message"] = "Loan type deleted successfully";
        } else {
            throw new Exception("Loan type not found");
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