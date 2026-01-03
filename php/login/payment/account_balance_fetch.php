<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $account_id = mysqli_real_escape_string($conn, $_POST['account_id'] ?? '');
    
    if (empty($companyid) || empty($account_id)) {
        $response["message"] = "Company ID and Account ID are required";
        echo json_encode($response);
        exit();
    }
    
    // Get opening balance from acledger
    $openingQuery = "SELECT opening FROM acledger 
                     WHERE id = '$account_id' AND companyid = '$companyid'";
    $openingResult = mysqli_query($conn, $openingQuery);
    
    $openingBalance = 0;
    if ($openingResult && $row = mysqli_fetch_assoc($openingResult)) {
        $openingBalance = floatval($row['opening'] ?? 0);
    }
    
    // Get total receipts for this account
    $receiptsQuery = "SELECT COALESCE(SUM(amount), 0) as total_receipts 
                      FROM receipt_entry 
                      WHERE receipt_from_id = '$account_id' 
                      AND companyid = '$companyid'";
    $receiptsResult = mysqli_query($conn, $receiptsQuery);
    
    $totalReceipts = 0;
    if ($receiptsResult && $row = mysqli_fetch_assoc($receiptsResult)) {
        $totalReceipts = floatval($row['total_receipts'] ?? 0);
    }
    
    // Get total payments for this account
    $paymentsQuery = "SELECT COALESCE(SUM(amount), 0) as total_payments 
                      FROM payment_entry 
                      WHERE payment_account_id = '$account_id' 
                      AND companyid = '$companyid'";
    $paymentsResult = mysqli_query($conn, $paymentsQuery);
    
    $totalPayments = 0;
    if ($paymentsResult && $row = mysqli_fetch_assoc($paymentsResult)) {
        $totalPayments = floatval($row['total_payments'] ?? 0);
    }
    
    // Calculate current balance
    $currentBalance = $openingBalance + $totalReceipts - $totalPayments;
    
    $response["status"] = "success";
    $response["message"] = "Balance retrieved successfully";
    $response["balance"] = number_format($currentBalance, 2, '.', '');
    $response["opening"] = $openingBalance;
    $response["total_receipts"] = $totalReceipts;
    $response["total_payments"] = $totalPayments;
    
} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>