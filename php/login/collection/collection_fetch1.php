<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error", 
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

$response = ["status" => "error", "message" => "Unknown error"];

try {
    // Check if required parameters are provided
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }
    
    if (!isset($_POST['loanno'])) {
        $response["message"] = "Loan number is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $loanno = mysqli_real_escape_string($conn, $_POST['loanno']);
    
    error_log("Fetching loan details for loan no: $loanno, company: $companyid");

    // Fetch loan details with penalty amount
    $loanSql = "SELECT 
                l.*, 
                c.customername, 
                c.mobile1,
                lt.loantype,
                lt.penaltyamount as fixed_penalty_amount
                FROM loanmaster l
                LEFT JOIN customermaster c ON l.customerid = c.id
                LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                WHERE l.loanno = '$loanno' 
                AND l.companyid = '$companyid'
                AND l.loanstatus = 'Active'";
    
    error_log("Loan SQL: $loanSql");
    
    $loanResult = mysqli_query($conn, $loanSql);
    
    if (!$loanResult) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    if (mysqli_num_rows($loanResult) == 0) {
        $response["message"] = "Active loan not found with loan number: $loanno";
        echo json_encode($response);
        exit();
    }
    
    $loan = mysqli_fetch_assoc($loanResult);
    $loanid = $loan['id'];
    $fixedPenalty = (float)$loan['fixed_penalty_amount'];
    
    error_log("Found loan ID: $loanid, Fixed Penalty Amount: $fixedPenalty");
    
    // Fetch payment schedule - Rule 3: Don't fetch fully paid EMI
    $scheduleSql = "SELECT * FROM loanschedule 
                    WHERE loanid = '$loanid' 
                    AND companyid = '$companyid'
                    AND (
                        status IN ('Pending', 'Partially Paid', 'Partially Paid Penalty', 'Unpaid')
                        OR (status = 'Paid' AND due_received < dueamount)
                        OR (status = 'Penalty Paid' AND penalty_received < '$fixedPenalty')
						OR (status = 'Partially Paid Penalty' AND penalty_received < '$fixedPenalty')  
                    )
                    ORDER BY dueno ASC";
    
    error_log("Schedule SQL: $scheduleSql");
    
    $scheduleResult = mysqli_query($conn, $scheduleSql);
    
    if (!$scheduleResult) {
        $response["message"] = "Schedule query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $schedule = [];
    $pendingPayments = [];
    
    while ($row = mysqli_fetch_assoc($scheduleResult)) {
        // Check if payment is fully paid
        $dueAmount = (float)$row['dueamount'];
        $dueReceived = (float)($row['due_received'] ?? 0);
        $penaltyReceived = (float)($row['penalty_received'] ?? 0);
        
        $isDueFullyPaid = ($dueReceived >= $dueAmount);
        $isPenaltyFullyPaid = ($penaltyReceived >= $fixedPenalty);
        
        // Only include if not fully paid
        if (!$isDueFullyPaid || !$isPenaltyFullyPaid) {
            if ($row['status'] == 'Pending' || $row['status'] == 'Partially Paid' || 
                $row['status'] == 'Partially Paid Penalty' || $row['status'] == 'Unpaid') {
                $pendingPayments[] = $row;
            }
            $schedule[] = $row;
        }
    }
    
    error_log("Found " . count($schedule) . " schedule entries, " . count($pendingPayments) . " pending");
    
    // Calculate totals including partial payments - Rule 5: Loan balance includes partial paid amount
    $totalPaid = 0;
    $totalPenaltyPaid = 0;
    $totalPending = 0;
    $totalPendingPenalty = 0;
    
    // Get ALL payments for accurate totals
    $allPaymentsSql = "SELECT * FROM loanschedule 
                       WHERE loanid = '$loanid' 
                       AND companyid = '$companyid'";
    $allPaymentsResult = mysqli_query($conn, $allPaymentsSql);
    
    while ($payment = mysqli_fetch_assoc($allPaymentsResult)) {
        $dueAmount = (float)$payment['dueamount'];
        $dueReceived = (float)($payment['due_received'] ?? 0);
        $penaltyReceived = (float)($payment['penalty_received'] ?? 0);
        
        // Rule 5: Include ALL paid amounts (full and partial)
        $totalPaid += $dueReceived;
        $totalPenaltyPaid += $penaltyReceived;
        
        // Calculate remaining amounts for pending payments
        if ($payment['status'] == 'Pending' || $payment['status'] == 'Partially Paid' || 
            $payment['status'] == 'Partially Paid Penalty' || $payment['status'] == 'Unpaid') {
            
            $remainingDue = $dueAmount - $dueReceived;
            $totalPending += $remainingDue;
            
            // For pending/unpaid payments that are overdue, include remaining penalty
            if ($payment['duedate'] && date('Y-m-d') > $payment['duedate']) {
                $remainingPenalty = $fixedPenalty - $penaltyReceived;
                if ($remainingPenalty > 0) {
                    $totalPendingPenalty += $remainingPenalty;
                }
            }
        }
    }
    
    // Calculate balances
    $loanAmount = (float)$loan['loanamount'];
    $loanPaid = $totalPaid; // Rule 5: Includes partial paid amount
    $loanBalance = $loanAmount - $loanPaid; // Correct loan balance calculation
    $penaltyBalance = $totalPendingPenalty;
    
    // Get last schedule entry for displaying next due date info
    $lastScheduleSql = "SELECT dueno, duedate FROM loanschedule 
                       WHERE loanid = '$loanid' 
                       AND companyid = '$companyid'
                       ORDER BY dueno DESC LIMIT 1";
    $lastScheduleResult = mysqli_query($conn, $lastScheduleSql);
    $lastSchedule = mysqli_fetch_assoc($lastScheduleResult);
    
    $response["status"] = "success";
    $response["message"] = "Loan details fetched successfully";
    $response["loan"] = array_merge($loan, [
        'fixed_penalty_amount' => $fixedPenalty
    ]);
    $response["schedule"] = $schedule;
    $response["last_schedule"] = $lastSchedule;
    $response["totals"] = [
        "loanPaid" => number_format($loanPaid, 2, '.', ''), // Total amount paid (including partial)
        "loanBalance" => number_format($loanBalance, 2, '.', ''), // Loan balance
        "pendingAmount" => number_format($totalPending, 2, '.', ''), // Pending due amount
        "penaltyPaid" => number_format($totalPenaltyPaid, 2, '.', ''), // Total penalty paid
        "fixedPenaltyAmount" => number_format($fixedPenalty, 2, '.', ''),
        "pendingPenalty" => number_format($totalPendingPenalty, 2, '.', ''), // Pending penalty
        "totalBalance" => number_format($loanBalance + $penaltyBalance, 2, '.', ''), // Total balance
    ];
    
    error_log("Response prepared successfully");
    error_log("Loan Amount: $loanAmount, Loan Paid: $loanPaid, Loan Balance: $loanBalance");

} catch (Exception $e) {
    error_log("Exception in collection_fetch.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>