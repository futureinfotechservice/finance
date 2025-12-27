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
    $serial_no = mysqli_real_escape_string($conn, $_POST['serial_no'] ?? '');
    $date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');
    $payment_account = mysqli_real_escape_string($conn, $_POST['payment_account'] ?? '');
    $payment_account_id = mysqli_real_escape_string($conn, $_POST['payment_account_id'] ?? '');
    $cash_bank = mysqli_real_escape_string($conn, $_POST['cash_bank'] ?? 'Cash');
    $amount = mysqli_real_escape_string($conn, $_POST['amount'] ?? '0.00');
    $description = mysqli_real_escape_string($conn, $_POST['description'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');

    // Validate required fields
    if (empty($payment_id) || empty($companyid) || empty($serial_no) || empty($date) || empty($payment_account) || empty($payment_account_id)) {
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

    // Check if serial number already exists for another payment
    $checkSql = "SELECT * FROM payment_entry WHERE serial_no = '$serial_no' AND companyid = '$companyid' AND id != '$payment_id'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) > 0) {
        throw new Exception("Serial number already exists for another payment");
    }

    // Update payment entry
    $sql = "UPDATE payment_entry 
            SET serial_no = '$serial_no', 
                date = '$date', 
                payment_account = '$payment_account', 
                payment_account_id = '$payment_account_id',
                cash_bank = '$cash_bank', 
                amount = '$amount', 
                description = '$description', 
                addedby = '$addedby'
            WHERE id = '$payment_id' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Payment entry updated successfully";
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