<?php
// due_date_pending_report.php
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
    $dueDate = isset($_POST['dueDate']) ? mysqli_real_escape_string($conn, $_POST['dueDate']) : null;
    $searchQuery = isset($_POST['search']) ? mysqli_real_escape_string($conn, $_POST['search']) : null;
    
    // Query to get pending dues by date
    $sql = "SELECT 
                ls.id,
                ls.loanid,
                ls.dueno,
                ls.duedate,
                ls.dueamount,
                ls.penaltypaid,
                ls.status,
                lm.loanno,
                lm.loanamount,
                lm.noofweeks,
                c.customername,
                c.mobile1,
                IFNULL((SELECT SUM(due_received_total) 
                        FROM collectionmaster 
                        WHERE loanid = lm.id AND companyid = '$companyid'), 0) as total_collected,
                IFNULL((SELECT SUM(penalty_received_total) 
                        FROM collectionmaster 
                        WHERE loanid = lm.id AND companyid = '$companyid'), 0) as total_penalty_collected
            FROM loanschedule ls
            INNER JOIN loanmaster lm ON ls.loanid = lm.id AND lm.companyid = '$companyid'
            INNER JOIN customermaster c ON lm.customerid = c.id AND c.companyid = '$companyid'
            WHERE ls.companyid = '$companyid'
                AND lm.loanstatus IN ('active', 'partially_paid')
                AND ls.status IN ('Pending', 'Overdue', 'Due')";
    
    if ($dueDate) {
        $sql .= " AND DATE(ls.duedate) = '$dueDate'";
    }
    
    if ($searchQuery) {
        $sql .= " AND (c.customername LIKE '%$searchQuery%' 
                      OR lm.loanno LIKE '%$searchQuery%')";
    }
    
    $sql .= " ORDER BY ls.duedate ASC, ls.dueno ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $items = [];
    $totalDueAmount = 0;
    $totalLoanBalance = 0;
    $totalPenaltyBalance = 0;
    $totalBalance = 0;
    
    while ($row = mysqli_fetch_assoc($result)) {
        $loanBalance = max(0, (float)$row['loanamount'] - (float)$row['total_collected']);
        $penaltyBalance = max(0, (float)$row['penaltypaid'] - (float)$row['total_penalty_collected']);
        $dueAmount = (float)$row['dueamount'];
        $totalBalance = $loanBalance + $penaltyBalance;
        
        $item = [
            'id' => $row['id'],
            'loanId' => $row['loanid'],
            'loanNo' => $row['loanno'],
            'customerName' => $row['customername'],
            'mobile' => $row['mobile1'],
            'dueNo' => (int)$row['dueno'],
            'dueDate' => $row['duedate'],
            'dueAmount' => $dueAmount,
            'loanAmount' => (float)$row['loanamount'],
            'noOfWeeks' => (int)$row['noofweeks'],
            'penaltyAmount' => (float)$row['penaltypaid'],
            'totalCollected' => (float)$row['total_collected'],
            'totalPenaltyCollected' => (float)$row['total_penalty_collected'],
            'loanBalance' => $loanBalance,
            'penaltyBalance' => $penaltyBalance,
            'totalBalance' => $totalBalance,
            'status' => $row['status'],
        ];
        
        $items[] = $item;
        
        // Calculate totals
        $totalDueAmount += $dueAmount;
        $totalLoanBalance += $loanBalance;
        $totalPenaltyBalance += $penaltyBalance;
        $totalBalance += $totalBalance;
    }
    
    $response["status"] = "success";
    $response["message"] = "Due date pending report fetched successfully";
    $response["items"] = $items;
    $response["summary"] = [
        'totalDueAmount' => $totalDueAmount,
        'totalLoanBalance' => $totalLoanBalance,
        'totalPenaltyBalance' => $totalPenaltyBalance,
        'totalBalance' => $totalBalance,
        'totalItems' => count($items)
    ];
    
} catch (Exception $e) {
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>