<?php
// outstanding_report.php (FIXED VERSION)
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

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
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $searchQuery = isset($_POST['search']) ? mysqli_real_escape_string($conn, $_POST['search']) : null;
    
    error_log("Fetching outstanding report for company: $companyid");

    // First, get all active loans with customer info
    $sql = "SELECT 
                lm.id as loan_id,
                lm.loanno,
                lm.loanamount,
                lm.interestamount,
                lm.noofweeks,
                lm.loanstatus,
                lm.startdate,
                lm.givenamount,
                c.customername,
                c.mobile1
            FROM loanmaster lm
            INNER JOIN customermaster c 
                ON lm.customerid = c.id 
                AND c.companyid = '$companyid'
            WHERE lm.companyid = '$companyid'
                AND lm.loanstatus IN ('active', 'partially_paid')";
    
    if ($searchQuery) {
        $sql .= " AND (c.customername LIKE '%$searchQuery%' 
                      OR lm.loanno LIKE '%$searchQuery%')";
    }
    
    $sql .= " ORDER BY lm.loanno ASC";
    
    error_log("Base SQL: $sql");
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $loans = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $loanId = $row['loan_id'];
        
        // Get loan schedule details for this specific loan
        $scheduleSql = "SELECT 
                            dueno,
                            dueamount,
                            penaltypaid,
                            status,
                            collectiondate,
                            paymentmode,olddueno 
                        FROM loanschedule 
                        WHERE loanid = '$loanId' 
                          AND companyid = '$companyid'
                        ORDER BY dueno";
        
        $scheduleResult = mysqli_query($conn, $scheduleSql);
        
        $totalDueAmount = 0;
        $totalPenalty = 0;
        $weeksPaid = 0;
        $weeksUnpaid = 0;
        $scheduleDetails = [];
        
        while ($scheduleRow = mysqli_fetch_assoc($scheduleResult)) {
            $scheduleDetails[] = $scheduleRow;
            $totalDueAmount += (float)$scheduleRow['dueamount'];
            $totalPenalty += (float)$scheduleRow['penaltypaid'];
            
            if ($scheduleRow['status'] == 'Paid') {
                $weeksPaid++;
            }
            else if ($scheduleRow['status'] == 'Penalty Paid') {
                // $weeksPaid++;
            }
			else if ($scheduleRow['olddueno'] != '0') {
                // $weeksPaid++;
            }
			else {
                $weeksUnpaid++;
            }
        }
        
        // Get collection details for this specific loan
        $collectionSql = "SELECT 
                            SUM(due_received_total) as total_collected,
                            SUM(penalty_received_total) as total_penalty_collected,
                            COUNT(DISTINCT dueno) as collection_count
                          FROM collectionmaster 
                          WHERE loanid = '$loanId' 
                            AND companyid = '$companyid'";
        
        $collectionResult = mysqli_query($conn, $collectionSql);
        $collectionData = mysqli_fetch_assoc($collectionResult);
        
        $totalCollected = (float)($collectionData['total_collected'] ?? 0);
        $totalPenaltyCollected = (float)($collectionData['total_penalty_collected'] ?? 0);
        $collectionCount = (int)($collectionData['collection_count'] ?? 0);
        
        // Get detailed collection breakdown
        $detailsSql = "SELECT 
                        cmd.dueno,
                        cmd.due_received,
                        cmd.penalty_received
                       FROM collectionmaster cm
                       INNER JOIN collectionmaster_details cmd 
                         ON cm.id = cmd.collectionid
                       WHERE cm.loanid = '$loanId' 
                         AND cm.companyid = '$companyid'";
        
        $detailsResult = mysqli_query($conn, $detailsSql);
        $collectionDetails = [];
        
        while ($detailRow = mysqli_fetch_assoc($detailsResult)) {
            $collectionDetails[] = [
                'dueno' => (int)$detailRow['dueno'],
                'due_received' => (float)$detailRow['due_received'],
                'penalty_received' => (float)$detailRow['penalty_received']
            ];
        }
        
        // Calculate balances
        $balancePrincipal = $row['loanamount'] - $totalCollected;
        $balancePenalty = $totalPenalty - $totalPenaltyCollected;
        
        // Calculate interest amount properly
        $interestAmount = (float)$row['interestamount'];
        $loanAmount = (float)$row['loanamount'];
        
        // If interest amount is not stored separately, calculate it
        if ($interestAmount == 0 && $row['givenamount'] > 0) {
            $givenAmount = (float)$row['givenamount'];
            $interestAmount = $loanAmount - $givenAmount;
        }
        
        $loan = [
            'id' => $loanId,
            'loanNo' => $row['loanno'],
            'customerName' => $row['customername'],
            'loanAmount' => $loanAmount,
            'interestAmount' => $interestAmount,
            'noOfWeeks' => (int)$row['noofweeks'],
            'penaltyAmount' => $totalPenalty,
            'collectionAmount' => $totalCollected,
            'penaltyCollected' => $totalPenaltyCollected,
            'balancePrincipal' => $balancePrincipal > 0 ? $balancePrincipal : 0,
            'balancePenalty' => $balancePenalty > 0 ? $balancePenalty : 0,
            'weeksPaid' => $weeksPaid,
            'weeksBalance' => $weeksUnpaid,
            'loanStatus' => $row['loanstatus'],
            'startDate' => $row['startdate'],
            'mobile1' => $row['mobile1'],
            'totalDueAmount' => $totalDueAmount,
            'scheduleDetails' => $scheduleDetails,
            'collectionDetails' => $collectionDetails
        ];
        
        $loans[] = $loan;
    }
    
    // Calculate summary
    $summary = [
        'totalLoanAmount' => 0,
        'totalInterestAmount' => 0,
        'totalPenaltyAmount' => 0,
        'totalCollectionAmount' => 0,
        'totalPenaltyCollected' => 0,
        'totalBalancePrincipal' => 0,
        'totalBalancePenalty' => 0,
        'totalWeeksPaid' => 0,
        'totalWeeksBalance' => 0,
        'totalLoans' => count($loans)
    ];
    
    foreach ($loans as $loan) {
        $summary['totalLoanAmount'] += $loan['loanAmount'];
        $summary['totalInterestAmount'] += $loan['interestAmount'];
        $summary['totalPenaltyAmount'] += $loan['penaltyAmount'];
        $summary['totalCollectionAmount'] += $loan['collectionAmount'];
        $summary['totalPenaltyCollected'] += $loan['penaltyCollected'];
        $summary['totalBalancePrincipal'] += $loan['balancePrincipal'];
        $summary['totalBalancePenalty'] += $loan['balancePenalty'];
        $summary['totalWeeksPaid'] += $loan['weeksPaid'];
        $summary['totalWeeksBalance'] += $loan['weeksBalance'];
    }
    
    $response["status"] = "success";
    $response["message"] = "Outstanding report fetched successfully";
    $response["loans"] = $loans;
    $response["summary"] = $summary;
    
    error_log("Found " . count($loans) . " outstanding loans");

} catch (Exception $e) {
    error_log("Exception in outstanding_report.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>