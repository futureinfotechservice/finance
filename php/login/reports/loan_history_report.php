<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    // Optional parameters
    $customerId = isset($_POST['customerid']) ? mysqli_real_escape_string($conn, $_POST['customerid']) : null;
    $loanNo = isset($_POST['loanno']) ? mysqli_real_escape_string($conn, $_POST['loanno']) : null;
    $fromDate = isset($_POST['fromdate']) ? mysqli_real_escape_string($conn, $_POST['fromdate']) : null;
    $toDate = isset($_POST['todate']) ? mysqli_real_escape_string($conn, $_POST['todate']) : null;

    // Fetch loan details
    $loanSql = "SELECT lm.*, c.customername, c.mobile1, c.mobile2, 
                       c.refer, c.refercontact, c.spousename, c.spousecontact, c.photourl,
                       lt.loantype
                FROM loanmaster lm
                LEFT JOIN customermaster c ON lm.customerid = c.id AND c.companyid = '$companyid'
                LEFT JOIN loantypemaster lt ON lm.loantypeid = lt.id AND lt.companyid = '$companyid'
                WHERE lm.companyid = '$companyid'";
    
    if ($customerId) {
        $loanSql .= " AND lm.customerid = '$customerId'";
    }
    
    if ($loanNo) {
        $loanSql .= " AND lm.loanno = '$loanNo'";
    }
    
    $loanSql .= " ORDER BY lm.startdate DESC LIMIT 1";
    
    $loanResult = mysqli_query($conn, $loanSql);
    
    if (!$loanResult) {
        $response["message"] = "Loan query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $loanData = [];
    if (mysqli_num_rows($loanResult) > 0) {
        $loanData = mysqli_fetch_assoc($loanResult);
        $loanId = $loanData['id'];
        
        // Calculate totals
        $totalPaidSql = "SELECT 
                            SUM(paidamount) as total_paid,
                            SUM(penaltypaid) as total_penalty_paid,
                            SUM(penalty_received) as total_penalty_received
                         FROM loanschedule 
                         WHERE loanid = '$loanId' 
                         AND companyid = '$companyid'";
        
        $totalResult = mysqli_query($conn, $totalPaidSql);
        $totals = mysqli_fetch_assoc($totalResult);
        
        $loanData['total_paid'] = $totals['total_paid'] ?? 0;
        $loanData['total_penalty_paid'] = $totals['total_penalty_paid'] ?? 0;
        $loanData['total_penalty_received'] = $totals['total_penalty_received'] ?? 0;
        $loanData['loan_balance'] = $loanData['loanamount'] - ($totals['total_paid'] ?? 0);
        $loanData['penalty_balance'] = $loanData['total_penalty_paid'] - ($totals['total_penalty_received'] ?? 0);
        
        // Fetch loan schedule
        $scheduleSql = "SELECT * FROM loanschedule 
                       WHERE loanid = '$loanId' 
                       AND companyid = '$companyid'";
        
        if ($fromDate && $toDate) {
            $scheduleSql .= " AND DATE(duedate) BETWEEN '$fromDate' AND '$toDate'";
        } elseif ($fromDate) {
            $scheduleSql .= " AND DATE(duedate) >= '$fromDate'";
        } elseif ($toDate) {
            $scheduleSql .= " AND DATE(duedate) <= '$toDate'";
        }
        
        $scheduleSql .= " ORDER BY dueno ASC";
        
        $scheduleResult = mysqli_query($conn, $scheduleSql);
        
        if (!$scheduleResult) {
            $response["message"] = "Schedule query error: " . mysqli_error($conn);
            echo json_encode($response);
            exit();
        }
        
        $scheduleData = [];
        while ($row = mysqli_fetch_assoc($scheduleResult)) {
            // Calculate balances for each row
            $scheduleSql2 = "SELECT 
                                SUM(paidamount) as running_paid,
                                SUM(penalty_received) as running_penalty
                             FROM loanschedule 
                             WHERE loanid = '$loanId' 
                             AND companyid = '$companyid'
                             AND dueno <= {$row['dueno']}";
            
            $balanceResult = mysqli_query($conn, $scheduleSql2);
            $balance = mysqli_fetch_assoc($balanceResult);
            
            $row['loan_balance'] = $loanData['loanamount'] - ($balance['running_paid'] ?? 0);
            $row['penalty_balance'] = $loanData['total_penalty_paid'] - ($balance['running_penalty'] ?? 0);
            $row['penalty_pending'] = $row['penaltypaid'] - $row['penalty_received'];
            
            $scheduleData[] = $row;
        }
        
        $loanData['schedule'] = $scheduleData;
        
        $response["status"] = "success";
        $response["message"] = "Loan history fetched successfully";
        $response["loan_data"] = $loanData;
        
    } else {
        $response["message"] = "No loan found for the selected criteria";
    }

} catch (Exception $e) {
    error_log("Exception in loan_history_report.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>