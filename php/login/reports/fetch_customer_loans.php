<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid']) || !isset($_POST['customerid'])) {
        $response["message"] = "Company ID and Customer ID are required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $customerId = mysqli_real_escape_string($conn, $_POST['customerid']);

    $sql = "SELECT id, loanno, loanamount, givenamount, interestamount, 
                   loanday, noofweeks, startdate, loanstatus
            FROM loanmaster 
            WHERE companyid = '$companyid' 
            AND customerid = '$customerId'
            ORDER BY startdate DESC";
    
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

} catch (Exception $e) {
    error_log("Exception in fetch_customer_loans.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>