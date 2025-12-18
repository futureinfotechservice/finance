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
    $loanid = isset($_POST['loanid']) ? mysqli_real_escape_string($conn, $_POST['loanid']) : '';
    
    if (!empty($loanid)) {
        // Fetch single loan with details
        $sql = "SELECT l.*, c.customername, lt.loantype 
                FROM loanmaster l
                LEFT JOIN customermaster c ON l.customerid = c.id
                LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                WHERE l.id = '$loanid' AND l.companyid = '$companyid'";
    } else {
        // Fetch all loans
        $sql = "SELECT l.*, c.customername, lt.loantype 
                FROM loanmaster l
                LEFT JOIN customermaster c ON l.customerid = c.id
                LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                WHERE l.companyid = '$companyid'
                ORDER BY l.createddate DESC";
    }
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $loans = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $loans[] = $row;
        }
        $response["status"] = "success";
        $response["loans"] = $loans;
    } else {
        $response["message"] = "Error fetching loans: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>