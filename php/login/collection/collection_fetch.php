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
    
    // Fetch payment schedule with SUM of penaltypaid
    $scheduleSql = "SELECT * FROM loanschedule 
                    WHERE loanid = '$loanid' 
                    AND companyid = '$companyid'
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
        if ($row['status'] == 'Pending') {
            $pendingPayments[] = $row;
        }
        $schedule[] = $row;
    }
    
    error_log("Found " . count($schedule) . " schedule entries, " . count($pendingPayments) . " pending");
    
    // Calculate totals including paid amount and sum of penaltypaid
    $totalPaid = 0;
    $totalPenaltyPaid = 0;
    $totalPending = 0;
    $totalPendingPenalty = 0;
    
    foreach ($schedule as $payment) {
        if ($payment['status'] == 'Paid' || $payment['status'] == 'Unpaid') {
            // Sum paidamount for paid payments
            $totalPaid += (float)$payment['paidamount'];
            
            // SUM of penaltypaid column
            $totalPenaltyPaid += (float)($payment['penaltypaid'] ?? 0);
        } else if ($payment['status'] == 'Pending') {
            $totalPending += (float)$payment['dueamount'];
            // For pending payments that are overdue, include fixed penalty
            if ($payment['duedate'] && date('Y-m-d') > $payment['duedate']) {
                $totalPendingPenalty += $fixedPenalty;
            }
        }
    }
    
    // Calculate balances
    $loanAmount = (float)$loan['loanamount'];
    $loanBalance = $totalPending;
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
        "loanPaid" => number_format($totalPaid, 2, '.', ''),
        "loanBalance" => number_format($loanBalance, 2, '.', ''),
        "pendingAmount" => number_format($totalPending, 2, '.', ''),
        "penaltyPaid" => number_format($totalPenaltyPaid, 2, '.', ''), // SUM of penaltypaid
        "fixedPenaltyAmount" => number_format($fixedPenalty, 2, '.', ''),
        "pendingPenalty" => number_format($totalPendingPenalty, 2, '.', ''),
        "totalBalance" => number_format($loanBalance + $penaltyBalance, 2, '.', ''),
    ];
    
    error_log("Response prepared successfully");

} catch (Exception $e) {
    error_log("Exception in collection_fetch.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>
