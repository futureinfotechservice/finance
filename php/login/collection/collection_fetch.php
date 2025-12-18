<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $loanno = isset($_POST['loanno']) ? mysqli_real_escape_string($conn, $_POST['loanno']) : '';
    
    if (empty($loanno)) {
        $response["message"] = "Loan number is required";
        echo json_encode($response);
        exit();
    }
    
    // Fetch loan details
    $loanSql = "SELECT 
                l.*, 
                c.customername, 
                c.mobile1,
                lt.loantype,
                lt.penaltyamount
                FROM loanmaster l
                LEFT JOIN customermaster c ON l.customerid = c.id
                LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                WHERE l.loanno = '$loanno' 
                AND l.companyid = '$companyid'
                AND l.loanstatus = 'Active'";
    
    $loanResult = mysqli_query($conn, $loanSql);
    
    if (!$loanResult || mysqli_num_rows($loanResult) == 0) {
        $response["message"] = "Active loan not found with loan number: $loanno";
        echo json_encode($response);
        exit();
    }
    
    $loan = mysqli_fetch_assoc($conn, $loanResult);
    
    // Fetch payment schedule
    $scheduleSql = "SELECT * FROM loanschedule 
                    WHERE loanid = '{$loan['id']}' 
                    AND companyid = '$companyid'
                    ORDER BY dueno ASC";
    
    $scheduleResult = mysqli_query($conn, $scheduleSql);
    
    $schedule = [];
    while ($row = mysqli_fetch_assoc($scheduleResult)) {
        $schedule[] = $row;
    }
    
    // Calculate totals
    $totalPaid = 0;
    $totalPenaltyPaid = 0;
    foreach ($schedule as $payment) {
        if ($payment['status'] == 'Paid') {
            $totalPaid += $payment['dueamount'];
            $totalPenaltyPaid += $payment['penaltypaid'];
        }
    }
    
    $response["status"] = "success";
    $response["message"] = "Loan details fetched successfully";
    $response["loan"] = $loan;
    $response["schedule"] = $schedule;
    $response["totals"] = [
        "loanPaid" => $totalPaid,
        "loanBalance" => $loan['loanamount'] - $totalPaid,
        "penaltyPaid" => $totalPenaltyPaid,
        "totalBalance" => ($loan['loanamount'] - $totalPaid) + $loan['penaltyamount']
    ];

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>