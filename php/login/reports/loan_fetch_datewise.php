<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    // Optional parameters
    $fromDate = isset($_POST['fromdate']) ? mysqli_real_escape_string($conn, $_POST['fromdate']) : null;
    $toDate = isset($_POST['todate']) ? mysqli_real_escape_string($conn, $_POST['todate']) : null;
    $customerId = isset($_POST['customerid']) ? mysqli_real_escape_string($conn, $_POST['customerid']) : null;
    $searchQuery = isset($_POST['search']) ? mysqli_real_escape_string($conn, $_POST['search']) : null;

    // Build base query
    $sql = "SELECT 
                lm.*,
                c.customername,
                c.mobile1,
                lt.loantype
            FROM loanmaster lm
            LEFT JOIN customermaster c ON lm.customerid = c.id AND c.companyid = '$companyid'
            LEFT JOIN loantypemaster lt ON lm.loantypeid = lt.id AND lt.companyid = '$companyid'
            WHERE lm.companyid = '$companyid'";

    // Add date filters if provided
    if ($fromDate && $toDate) {
        $sql .= " AND DATE(lm.startdate) BETWEEN '$fromDate' AND '$toDate'";
    } elseif ($fromDate) {
        $sql .= " AND DATE(lm.startdate) >= '$fromDate'";
    } elseif ($toDate) {
        $sql .= " AND DATE(lm.startdate) <= '$toDate'";
    }

    // Add customer filter if provided
    if ($customerId && $customerId != 'null') {
        $sql .= " AND lm.customerid = '$customerId'";
    }

    // Add search filter if provided
    if ($searchQuery) {
        $sql .= " AND (c.customername LIKE '%$searchQuery%' 
                      OR lm.loanno LIKE '%$searchQuery%')";
    }

    $sql .= " ORDER BY lm.startdate DESC, lm.createddate DESC";

    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $loans = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $loans[] = $row;
    }
    
    $response["status"] = "success";
    $response["message"] = "Loans fetched successfully";
    $response["loans"] = $loans;
    $response["total"] = count($loans);

} catch (Exception $e) {
    error_log("Exception in loan_fetch_datewise.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>