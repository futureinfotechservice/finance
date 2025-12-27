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
    $serial_no = mysqli_real_escape_string($conn, $_POST['serial_no'] ?? '');
    $date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');
    $receipt_from = mysqli_real_escape_string($conn, $_POST['receipt_from'] ?? '');
    $receipt_from_id = mysqli_real_escape_string($conn, $_POST['receipt_from_id'] ?? '');
    $cash_bank = mysqli_real_escape_string($conn, $_POST['cash_bank'] ?? 'Cash');
    $amount = mysqli_real_escape_string($conn, $_POST['amount'] ?? '0.00');
    $description = mysqli_real_escape_string($conn, $_POST['description'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');

    // Validate required fields
    if (empty($receipt_id) || empty($companyid) || empty($serial_no) || empty($date) || empty($receipt_from) || empty($receipt_from_id)) {
        throw new Exception("Required fields are missing");
    }

    // Validate cash_bank (only Cash or Bank)
    if (!in_array($cash_bank, ['Cash', 'Bank'])) {
        $cash_bank = 'Cash'; // Default to Cash
    }

    // Validate amount
    if (!is_numeric($amount) || floatval($amount) <= 0) {
        throw new Exception("Please enter a valid amount");
    }

    // Check if serial number already exists for another receipt
    $checkSql = "SELECT * FROM receipt_entry WHERE serial_no = '$serial_no' AND companyid = '$companyid' AND id != '$receipt_id'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) > 0) {
        throw new Exception("Serial number already exists for another receipt");
    }

    // Update receipt entry
    $sql = "UPDATE receipt_entry 
            SET serial_no = '$serial_no', 
                date = '$date', 
                receipt_from = '$receipt_from', 
                receipt_from_id = '$receipt_from_id',
                cash_bank = '$cash_bank', 
                amount = '$amount', 
                description = '$description', 
                addedby = '$addedby'
            WHERE id = '$receipt_id' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Receipt entry updated successfully";
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