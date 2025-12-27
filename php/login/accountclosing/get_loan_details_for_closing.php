<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "", 
             "loan_amount" => "0.00", "loan_paid" => "0.00", "balance_amount" => "0.00",
             "penalty_amount" => "0.00", "penalty_collected" => "0.00", "penalty_balance" => "0.00"];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $loanid = mysqli_real_escape_string($conn, $_POST['loanid'] ?? '');

    if (empty($companyid) || empty($loanid)) {
        throw new Exception("Required fields are missing");
    }

    // Get loan basic info
    $sql = "SELECT loanamount, loanamount as givenamount FROM loanmaster 
            WHERE id = '$loanid' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $sql);
    
    if (mysqli_num_rows($result) > 0) {
        $loan = mysqli_fetch_assoc($result);
        $loan_amount = $loan['loanamount'];
        $given_amount = $loan['givenamount'];
        
        // Get loan payments from schedule
        $sql2 = "SELECT 
                    SUM(paidamount) as total_paid,
                    SUM(penalty_received) as penalty_collected,
                    SUM(penaltypaid) as penalty_amount
                 FROM loanschedule 
                 WHERE loanid = '$loanid' AND companyid = '$companyid'";
        $result2 = mysqli_query($conn, $sql2);
        
        if (mysqli_num_rows($result2) > 0) {
            $schedule = mysqli_fetch_assoc($result2);
            $loan_paid = $schedule['total_paid'] ?? 0;
            $penalty_collected = $schedule['penalty_collected'] ?? 0;
            $penalty_amount = $schedule['penalty_amount'] ?? 0;
            
            // Calculate balances
            $balance_amount = max(0, $given_amount - $loan_paid);
            $penalty_balance = max(0, $penalty_amount - $penalty_collected);
            
            $response["status"] = "success";
            $response["message"] = "Loan details fetched successfully";
            $response["loan_amount"] = $loan_amount;
            $response["loan_paid"] = $loan_paid;
            $response["balance_amount"] = $balance_amount;
            $response["penalty_amount"] = $penalty_amount;
            $response["penalty_collected"] = $penalty_collected;
            $response["penalty_balance"] = $penalty_balance;
        }
    } else {
        throw new Exception("Loan not found");
    }

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
if ($conn) {
    mysqli_close($conn);
}
?>