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
    
    // Fetch payment schedule - Exclude 'Paid' and 'Penalty Paid' status
    // 'Paid' means due amount is fully paid
    // 'Penalty Paid' means penalty is fully paid
    // Only show payments that are still pending or partially paid
    $scheduleSql = "SELECT * FROM loanschedule 
                    WHERE loanid = '$loanid' 
                    AND companyid = '$companyid'
                    AND status IN ('Pending', 'Partially Paid', 'Partially Paid Penalty', 'Unpaid')
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
        // Get all relevant data
        $dueAmount = (float)$row['dueamount'];
        $dueReceived = (float)($row['due_received'] ?? 0);
        $penaltyReceived = (float)($row['penalty_received'] ?? 0);
        $status = $row['status'];
        
        // Determine if payment is fully paid
        $isDueFullyPaid = ($dueReceived >= $dueAmount);
        $isPenaltyFullyPaid = ($penaltyReceived >= $fixedPenalty);
        
        // IMPORTANT: Check if payment has "Partially Paid Penalty" status
        $hasPartialPenaltyPayment = ($status == 'Partially Paid Penalty');
        
        // Check if payment is overdue
        $isOverdue = false;
        $currentDate = date('Y-m-d');
        if ($row['duedate'] && $currentDate > $row['duedate']) {
            $isOverdue = true;
        }
        
        // Calculate remaining penalty amount
        $remainingPenalty = 0;
        if ($isOverdue) {
            $remainingPenalty = $fixedPenalty - $penaltyReceived;
            if ($remainingPenalty < 0) $remainingPenalty = 0;
        }
        
        // Only include if not fully paid (due AND penalty)
        // Since we already excluded 'Paid' and 'Penalty Paid', we should include all remaining
        if (!$isDueFullyPaid || !$isPenaltyFullyPaid) {
            // Add additional flags for frontend validation
            $row['is_due_fully_paid'] = $isDueFullyPaid;
            $row['is_penalty_fully_paid'] = $isPenaltyFullyPaid;
            $row['has_partial_penalty_payment'] = $hasPartialPenaltyPayment;
            $row['is_overdue'] = $isOverdue;
            $row['remaining_penalty'] = $remainingPenalty;
            $row['already_received_due'] = $dueReceived;
            $row['already_received_penalty'] = $penaltyReceived;
            $row['remaining_due'] = $dueAmount - $dueReceived;
            
            // All payments in this result are pending/partially paid
            $pendingPayments[] = $row;
            $schedule[] = $row;
        }
    }
    
    error_log("Found " . count($schedule) . " schedule entries, " . count($pendingPayments) . " pending");
    
    // Calculate totals including partial payments
    $totalPaid = 0;
    $totalPenaltyPaid = 0;
    $totalPending = 0;
    $totalPendingPenalty = 0;
    
    // Get ALL payments for accurate totals (including 'Paid' and 'Penalty Paid' for calculations)
    $allPaymentsSql = "SELECT * FROM loanschedule 
                       WHERE loanid = '$loanid' 
                       AND companyid = '$companyid'";
    $allPaymentsResult = mysqli_query($conn, $allPaymentsSql);
    
    while ($payment = mysqli_fetch_assoc($allPaymentsResult)) {
        $dueAmount = (float)$payment['dueamount'];
        $dueReceived = (float)($payment['due_received'] ?? 0);
        $penaltyReceived = (float)($payment['penalty_received'] ?? 0);
        $paymentStatus = $payment['status'];
        
        // Include ALL paid amounts (full and partial)
        $totalPaid += $dueReceived;
        $totalPenaltyPaid += $penaltyReceived;
        
        // Calculate remaining amounts for pending payments
        // Exclude 'Paid' and 'Penalty Paid' from pending calculations
        if ($paymentStatus == 'Pending' || $paymentStatus == 'Partially Paid' || 
            $paymentStatus == 'Partially Paid Penalty' || $paymentStatus == 'Unpaid') {
            
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
    $loanPaid = $totalPaid;
    $loanBalance = $loanAmount - $loanPaid;
    $penaltyBalance = $totalPendingPenalty;
    
    // Get last schedule entry for displaying next due date info
    // Include ALL payments for getting accurate last due date
    $lastScheduleSql = "SELECT dueno, duedate FROM loanschedule 
                       WHERE loanid = '$loanid' 
                       AND companyid = '$companyid'
                       ORDER BY dueno DESC LIMIT 1";
    $lastScheduleResult = mysqli_query($conn, $lastScheduleSql);
    $lastSchedule = mysqli_fetch_assoc($lastScheduleResult);
    
    // Check for any payments with "Partially Paid Penalty" status
    $partialPenaltyPayments = [];
    $partialPenaltySql = "SELECT dueno, penalty_received, status FROM loanschedule 
                         WHERE loanid = '$loanid' 
                         AND companyid = '$companyid'
                         AND status = 'Partially Paid Penalty'";
    $partialPenaltyResult = mysqli_query($conn, $partialPenaltySql);
    while ($row = mysqli_fetch_assoc($partialPenaltyResult)) {
        $partialPenaltyPayments[] = $row;
    }
    
    // Check for any payments with "Paid" status (for debugging)
    $paidPayments = [];
    $paidSql = "SELECT dueno, due_received, penalty_received, status FROM loanschedule 
                WHERE loanid = '$loanid' 
                AND companyid = '$companyid'
                AND status = 'Paid'";
    $paidResult = mysqli_query($conn, $paidSql);
    while ($row = mysqli_fetch_assoc($paidResult)) {
        $paidPayments[] = $row;
    }
    
    // Check for any payments with "Penalty Paid" status (for debugging)
    $penaltyPaidPayments = [];
    $penaltyPaidSql = "SELECT dueno, due_received, penalty_received, status FROM loanschedule 
                      WHERE loanid = '$loanid' 
                      AND companyid = '$companyid'
                      AND status = 'Penalty Paid'";
    $penaltyPaidResult = mysqli_query($conn, $penaltyPaidSql);
    while ($row = mysqli_fetch_assoc($penaltyPaidResult)) {
        $penaltyPaidPayments[] = $row;
    }
    
    $response["status"] = "success";
    $response["message"] = "Loan details fetched successfully";
    $response["loan"] = array_merge($loan, [
        'fixed_penalty_amount' => $fixedPenalty
    ]);
    $response["schedule"] = $schedule;
    $response["last_schedule"] = $lastSchedule;
    $response["partial_penalty_payments"] = $partialPenaltyPayments; // For debugging/validation
    $response["paid_payments"] = $paidPayments; // For debugging (excluded from schedule)
    $response["penalty_paid_payments"] = $penaltyPaidPayments; // For debugging (excluded from schedule)
    $response["totals"] = [
        "loanPaid" => number_format($loanPaid, 2, '.', ''), 
        "loanBalance" => number_format($loanBalance, 2, '.', ''), 
        "pendingAmount" => number_format($totalPending, 2, '.', ''), 
        "penaltyPaid" => number_format($totalPenaltyPaid, 2, '.', ''), 
        "fixedPenaltyAmount" => number_format($fixedPenalty, 2, '.', ''),
        "pendingPenalty" => number_format($totalPendingPenalty, 2, '.', ''), 
        "totalBalance" => number_format($loanBalance + $penaltyBalance, 2, '.', ''), 
    ];
    
    error_log("Response prepared successfully");
    error_log("Found " . count($schedule) . " pending/partially paid schedule entries");
    error_log("Found " . count($partialPenaltyPayments) . " payments with 'Partially Paid Penalty' status");
    error_log("Found " . count($paidPayments) . " payments with 'Paid' status (excluded from schedule)");
    error_log("Found " . count($penaltyPaidPayments) . " payments with 'Penalty Paid' status (excluded from schedule)");

} catch (Exception $e) {
    error_log("Exception in collection_fetch.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>