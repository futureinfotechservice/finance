<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$response = ["status" => "error", "message" => "Unknown error", "loans" => []];

try {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    $sql = "SELECT 
            l.id,
            l.loanno,
            c.customername,
            l.loanamount,
            l.loanstatus
            FROM loanmaster l
            LEFT JOIN customermaster c ON l.customerid = c.id
            WHERE l.companyid = '$companyid'
            AND l.loanstatus = 'Active'
            ORDER BY l.loanno ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $loans = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $loans[] = [
            'id' => (string)$row['id'],
            'loanno' => $row['loanno'] ?? '',
            'customername' => $row['customername'] ?? '',
            'loanamount' => $row['loanamount'] ?? '0',
            'display' => ($row['loanno'] ?? '') . ' - ' . ($row['customername'] ?? '')
        ];
    }
    
    $response["status"] = "success";
    $response["message"] = "Active loans fetched successfully";
    $response["loans"] = $loans;
    $response["count"] = count($loans);

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>