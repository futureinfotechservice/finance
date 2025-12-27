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

    if (empty($companyid)) {
        throw new Exception("Company ID is required");
    }

    // Fetch receipt entries
    $sql = "SELECT id, companyid, serial_no, date, receipt_from, receipt_from_id, cash_bank, amount, description, addedby, created_at 
            FROM receipt_entry 
            WHERE companyid = '$companyid' 
            ORDER BY id DESC";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $receipts = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $receipts[] = [
                "id" => $row['id'],
                "companyid" => $row['companyid'],
                "serial_no" => $row['serial_no'],
                "date" => $row['date'],
                "receipt_from" => $row['receipt_from'],
                "receipt_from_id" => $row['receipt_from_id'],
                "cash_bank" => $row['cash_bank'],
                "amount" => $row['amount'],
                "description" => $row['description'],
                "addedby" => $row['addedby'],
                "created_at" => $row['created_at']
            ];
        }
        
        $response["status"] = "success";
        $response["message"] = "Receipt entries fetched successfully";
        $response["data"] = $receipts;
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