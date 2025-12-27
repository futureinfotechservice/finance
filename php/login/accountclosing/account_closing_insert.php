<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $serial_no = mysqli_real_escape_string($conn, $_POST['serial_no'] ?? '');
    $date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');
    $customer_id = mysqli_real_escape_string($conn, $_POST['customer_id'] ?? '');
    $customer_name = mysqli_real_escape_string($conn, $_POST['customer_name'] ?? '');
    $loan_id = mysqli_real_escape_string($conn, $_POST['loan_id'] ?? '');
    $loan_no = mysqli_real_escape_string($conn, $_POST['loan_no'] ?? '');
    $loan_amount = mysqli_real_escape_string($conn, $_POST['loan_amount'] ?? '0.00');
    $loan_paid = mysqli_real_escape_string($conn, $_POST['loan_paid'] ?? '0.00');
    $balance_amount = mysqli_real_escape_string($conn, $_POST['balance_amount'] ?? '0.00');
    $penalty_amount = mysqli_real_escape_string($conn, $_POST['penalty_amount'] ?? '0.00');
    $penalty_collected = mysqli_real_escape_string($conn, $_POST['penalty_collected'] ?? '0.00');
    $penalty_balance = mysqli_real_escape_string($conn, $_POST['penalty_balance'] ?? '0.00');
    $discount_principle = mysqli_real_escape_string($conn, $_POST['discount_principle'] ?? '0.00');
    $discount_penalty = mysqli_real_escape_string($conn, $_POST['discount_penalty'] ?? '0.00');
    $final_settlement = mysqli_real_escape_string($conn, $_POST['final_settlement'] ?? '0.00');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');

    // Validate required fields
    if (empty($companyid) || empty($serial_no) || empty($date) || empty($customer_id) || empty($loan_id)) {
        throw new Exception("Required fields are missing");
    }

    // Check if serial number already exists
    $checkSql = "SELECT * FROM account_closing WHERE serial_no = '$serial_no' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) > 0) {
        throw new Exception("Serial number already exists");
    }

    // Start transaction
    mysqli_begin_transaction($conn);

    try {
        // 1. Insert account closing record
        $sql1 = "INSERT INTO account_closing 
                (companyid, serial_no, date, customer_id, customer_name, loan_id, loan_no, 
                 loan_amount, loan_paid, balance_amount, penalty_amount, penalty_collected, 
                 penalty_balance, discount_principle, discount_penalty, final_settlement, addedby) 
                VALUES ('$companyid', '$serial_no', '$date', '$customer_id', '$customer_name', 
                        '$loan_id', '$loan_no', '$loan_amount', '$loan_paid', '$balance_amount', 
                        '$penalty_amount', '$penalty_collected', '$penalty_balance', 
                        '$discount_principle', '$discount_penalty', '$final_settlement', '$addedby')";

        if (!mysqli_query($conn, $sql1)) {
            throw new Exception("Failed to insert account closing: " . mysqli_error($conn));
        }

        $closing_id = mysqli_insert_id($conn);

        // 2. Update loan status to 'Closed'
        $sql2 = "UPDATE loanmaster SET loanstatus = 'Closed' 
                WHERE id = '$loan_id' AND companyid = '$companyid'";
        
        if (!mysqli_query($conn, $sql2)) {
            throw new Exception("Failed to update loan status: " . mysqli_error($conn));
        }

        // 3. Update all remaining schedules as 'Closed'
        $sql3 = "UPDATE loanschedule SET status = 'Closed' 
                WHERE loanid = '$loan_id' AND companyid = '$companyid' AND status != 'Paid'";
        
        if (!mysqli_query($conn, $sql3)) {
            throw new Exception("Failed to update loan schedules: " . mysqli_error($conn));
        }

        // Commit transaction
        mysqli_commit($conn);

        $response["status"] = "success";
        $response["message"] = "Account closed successfully";
        $response["id"] = $closing_id;

    } catch (Exception $e) {
        // Rollback transaction on error
        mysqli_rollback($conn);
        throw $e;
    }

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
if ($conn) {
    mysqli_close($conn);
}
?>