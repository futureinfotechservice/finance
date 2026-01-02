<?php
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
    // Check if required parameters are provided
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    // Optional parameters
    $fromDate = isset($_POST['fromdate']) ? mysqli_real_escape_string($conn, $_POST['fromdate']) : null;
    $toDate = isset($_POST['todate']) ? mysqli_real_escape_string($conn, $_POST['todate']) : null;
    $searchQuery = isset($_POST['search']) ? mysqli_real_escape_string($conn, $_POST['search']) : null;

    error_log("Fetching collection history for company: $companyid");

    // Build base query
    $sql = "SELECT 
                cm.id as collection_id,
                cm.collectionno,
                cm.collectiondate,
                cm.paymentmode,
                cm.totalamount,
                cm.totalpenalty,
                cm.collectedby,
                cm.createddate as collection_created,
                
                cmd.id as detail_id,
                cmd.dueno,
                cmd.due_received,
                cmd.penalty_received,
                cmd.createddate as detail_created,
                
                lm.loanno,
                lm.loanamount,
                lm.loanstatus,
                
                c.customername,
                c.mobile1,
                c.address
                
            FROM collectionmaster cm
            
            INNER JOIN collectionmaster_details cmd 
                ON cm.id = cmd.collectionid 
                AND cm.companyid = '$companyid'
                
            INNER JOIN loanmaster lm 
                ON cm.loanid = lm.id 
                AND lm.companyid = '$companyid'
                
            INNER JOIN customermaster c 
                ON lm.customerid = c.id 
                AND c.companyid = '$companyid'
                
            WHERE cm.companyid = '$companyid'";

    // Add date filters if provided
    if ($fromDate && $toDate) {
        $sql .= " AND DATE(cm.collectiondate) BETWEEN '$fromDate' AND '$toDate'";
    } elseif ($fromDate) {
        $sql .= " AND DATE(cm.collectiondate) >= '$fromDate'";
    } elseif ($toDate) {
        $sql .= " AND DATE(cm.collectiondate) <= '$toDate'";
    }

    // Add search filter if provided
    if ($searchQuery) {
        $sql .= " AND (c.customername LIKE '%$searchQuery%' 
                      OR lm.loanno LIKE '%$searchQuery%'
                      OR cm.collectionno LIKE '%$searchQuery%')";
    }

    $sql .= " ORDER BY cm.collectiondate ASC, cmd.dueno ASC";

    error_log("Collection History SQL: $sql");
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $collections = [];
    $collectionDetails = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $collectionId = $row['collection_id'];
        
        // Group by collection
        if (!isset($collections[$collectionId])) {
            $collections[$collectionId] = [
                'id' => $row['collection_id'],
                'collectionno' => $row['collectionno'],
                'loanno' => $row['loanno'],
                'customername' => $row['customername'],
                'collectiondate' => $row['collectiondate'],
                'paymentmode' => $row['paymentmode'],
                'totalamount' => 0,
                'totalpenalty' => 0,
                'collectedby' => $row['collectedby'],
                'mobile1' => $row['mobile1'],
                'address' => $row['address'],
                'loanamount' => $row['loanamount'],
                'loanstatus' => $row['loanstatus'],
                'details' => []
            ];
        }
        
        // Add due details
        $detail = [
            'detail_id' => $row['detail_id'],
            'dueno' => (int)$row['dueno'],
            'due_received' => (float)$row['due_received'],
            'penalty_received' => (float)$row['penalty_received'],
            'detail_created' => $row['detail_created']
        ];
        
        $collections[$collectionId]['details'][] = $detail;
        
        // Update totals
        $collections[$collectionId]['totalamount'] += (float)$row['due_received'];
        $collections[$collectionId]['totalpenalty'] += (float)$row['penalty_received'];
    }
    
    // Convert to indexed array
    $collectionList = array_values($collections);
    
    // Calculate summary statistics
    $totalCashCollected = 0;
    $totalBankCollected = 0;
    $totalDueAmount = 0;
    $totalPenaltyAmount = 0;
    
    foreach ($collectionList as $collection) {
        $dueAmount = (float)$collection['totalamount'];
        $penaltyAmount = (float)$collection['totalpenalty'];
        
        $totalDueAmount += $dueAmount;
        $totalPenaltyAmount += $penaltyAmount;
        
        if (strtolower($collection['paymentmode']) == 'cash') {
            $totalCashCollected += $dueAmount + $penaltyAmount;
        } else {
            $totalBankCollected += $dueAmount + $penaltyAmount;
        }
    }
    
    $response["status"] = "success";
    $response["message"] = "Collection history fetched successfully";
    $response["collections"] = $collectionList;
    $response["summary"] = [
        "totalCollections" => count($collectionList),
        "totalDueAmount" => number_format($totalDueAmount, 2, '.', ''),
        "totalPenaltyAmount" => number_format($totalPenaltyAmount, 2, '.', ''),
        "totalCashCollected" => number_format($totalCashCollected, 2, '.', ''),
        "totalBankCollected" => number_format($totalBankCollected, 2, '.', ''),
        "totalAmountCollected" => number_format($totalCashCollected + $totalBankCollected, 2, '.', '')
    ];
    
    error_log("Found " . count($collectionList) . " collections with details");

} catch (Exception $e) {
    error_log("Exception in collection_history_report.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>