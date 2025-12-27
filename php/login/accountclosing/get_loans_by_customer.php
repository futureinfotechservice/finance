<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "", "data" => []];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $customerid = mysqli_real_escape_string($conn, $_POST['customerid'] ?? '');

    if (empty($companyid) || empty($customerid)) {
        throw new Exception("Required fields are missing");
    }

    // Fetch active loans for customer
    $sql = "SELECT id, loanno, loanamount, givenamount, loanstatus 
            FROM loanmaster 
            WHERE companyid = '$companyid' 
            AND customerid = '$customerid' 
            AND loanstatus IN ('Active', 'Partially Paid')
            ORDER BY id DESC";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $loans = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $loans[] = [
                "id" => $row['id'],
                "loanno" => $row['loanno'],
                "loanamount" => $row['loanamount'],
                "givenamount" => $row['givenamount'],
                "loanstatus" => $row['loanstatus'],
            ];
        }
        
        $response["status"] = "success";
        $response["message"] = "Loans fetched successfully";
        $response["data"] = $loans;
    } else {
        throw new Exception("Database error: " . mysqli_error($conn));
    }

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
if ($conn) {
    mysqli_close($conn);
}
?>