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

    // Fetch active customers
    $sql = "SELECT id, customername, mobile1 
            FROM customermaster 
            WHERE companyid = '$companyid' AND activestatus = '1'
            ORDER BY customername ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $customers = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $customers[] = [
                "id" => $row['id'],
                "customername" => $row['customername'],
                "mobile1" => $row['mobile1'],
            ];
        }
        
        $response["status"] = "success";
        $response["message"] = "Customers fetched successfully";
        $response["data"] = $customers;
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