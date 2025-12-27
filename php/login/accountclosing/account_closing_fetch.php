<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "", "data" => []];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($companyid)) {
        throw new Exception("Company ID is required");
    }

    // Option 1: Set collation at connection level (recommended)
    mysqli_query($conn, "SET NAMES 'utf8mb4' COLLATE 'utf8mb4_unicode_ci'");
    
    // Option 2: Modify the query to handle collation mismatch
    $sql = "SELECT 
                ac.id,
                ac.companyid,
                ac.serial_no,
                ac.date,
                ac.customer_id,
                ac.customer_name,
                ac.loan_id,
                ac.loan_no,
                ac.loan_amount,
                ac.loan_paid,
                ac.balance_amount,
                ac.penalty_amount,
                ac.penalty_collected,
                ac.penalty_balance,
                ac.discount_principle,
                ac.discount_penalty,
                ac.final_settlement,
                ac.addedby,
                ac.created_at,
                cm.customername as full_customer_name,
                cm.mobile1 as customer_mobile,
                lm.loanamount as original_loan_amount,
                lm.givenamount as given_loan_amount,
                lm.loanstatus as original_loan_status
            FROM account_closing ac
            LEFT JOIN customermaster cm ON cm.id = ac.customer_id 
                AND cm.companyid = ac.companyid 
                COLLATE utf8mb4_unicode_ci
            LEFT JOIN loanmaster lm ON lm.id = ac.loan_id 
                AND lm.companyid = ac.companyid 
                COLLATE utf8mb4_unicode_ci
            WHERE ac.companyid = '$companyid' 
            ORDER BY ac.id DESC";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $closings = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $closings[] = [
                "id" => $row['id'],
                "companyid" => $row['companyid'],
                "serial_no" => $row['serial_no'],
                "date" => $row['date'],
                "customer_id" => $row['customer_id'],
                "customer_name" => $row['customer_name'],
                "loan_id" => $row['loan_id'],
                "loan_no" => $row['loan_no'],
                "loan_amount" => $row['loan_amount'],
                "loan_paid" => $row['loan_paid'],
                "balance_amount" => $row['balance_amount'],
                "penalty_amount" => $row['penalty_amount'],
                "penalty_collected" => $row['penalty_collected'],
                "penalty_balance" => $row['penalty_balance'],
                "discount_principle" => $row['discount_principle'],
                "discount_penalty" => $row['discount_penalty'],
                "final_settlement" => $row['final_settlement'],
                "addedby" => $row['addedby'],
                "created_at" => $row['created_at'],
                "full_customer_name" => $row['full_customer_name'],
                "customer_mobile" => $row['customer_mobile'],
                "original_loan_amount" => $row['original_loan_amount'],
                "given_loan_amount" => $row['given_loan_amount'],
                "original_loan_status" => $row['original_loan_status']
            ];
        }
        
        $response["status"] = "success";
        $response["message"] = "Account closings fetched successfully";
        $response["data"] = $closings;
        
        // Also return summary statistics
        $summarySql = "SELECT 
                        COUNT(*) as total_closings,
                        COALESCE(SUM(loan_amount), 0) as total_loan_amount,
                        COALESCE(SUM(loan_paid), 0) as total_loan_paid,
                        COALESCE(SUM(balance_amount), 0) as total_balance,
                        COALESCE(SUM(penalty_amount), 0) as total_penalty,
                        COALESCE(SUM(penalty_collected), 0) as total_penalty_collected,
                        COALESCE(SUM(penalty_balance), 0) as total_penalty_balance,
                        COALESCE(SUM(discount_principle), 0) as total_discount_principle,
                        COALESCE(SUM(discount_penalty), 0) as total_discount_penalty,
                        COALESCE(SUM(final_settlement), 0) as total_final_settlement
                    FROM account_closing 
                    WHERE companyid = '$companyid'";
        
        $summaryResult = mysqli_query($conn, $summarySql);
        if ($summaryResult && mysqli_num_rows($summaryResult) > 0) {
            $summary = mysqli_fetch_assoc($summaryResult);
            $response["summary"] = [
                "total_closings" => $summary['total_closings'] ?? 0,
                "total_loan_amount" => $summary['total_loan_amount'] ?? '0.00',
                "total_loan_paid" => $summary['total_loan_paid'] ?? '0.00',
                "total_balance" => $summary['total_balance'] ?? '0.00',
                "total_penalty" => $summary['total_penalty'] ?? '0.00',
                "total_penalty_collected" => $summary['total_penalty_collected'] ?? '0.00',
                "total_penalty_balance" => $summary['total_penalty_balance'] ?? '0.00',
                "total_discount_principle" => $summary['total_discount_principle'] ?? '0.00',
                "total_discount_penalty" => $summary['total_discount_penalty'] ?? '0.00',
                "total_final_settlement" => $summary['total_final_settlement'] ?? '0.00'
            ];
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