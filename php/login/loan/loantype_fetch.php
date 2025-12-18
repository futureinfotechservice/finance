<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = ["status" => "error", "message" => "Unknown error"];

try {
    // Check if companyid is provided
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $search = isset($_POST['search']) ? mysqli_real_escape_string($conn, $_POST['search']) : '';
    
    // Build query
    $sql = "SELECT * FROM loantypemaster WHERE companyid = '$companyid'";
    
    // Add search filter if provided
    if (!empty($search)) {
        $sql .= " AND (loantype LIKE '%$search%' OR collectionday LIKE '%$search%')";
    }
    
    $sql .= " ORDER BY loantype ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $loanTypes = [];
    while ($row = mysqli_fetch_assoc($result)) {
        // Format the data
        $loanTypes[] = [
            'id' => $row['id'],
            'loantype' => $row['loantype'],
            'collectionday' => $row['collectionday'],
            'noofweeks' => $row['noofweeks'],
            'penaltyamount' => $row['penaltyamount'],
            'companyid' => $row['companyid'],
            'addedby' => $row['addedby'],
            // 'activestatus' => $row['activestatus'],
            // 'createddate' => $row['createddate']
        ];
    }
    
    $response["status"] = "success";
    $response["message"] = "Loan types fetched successfully";
    $response["loanTypes"] = $loanTypes;
    $response["count"] = count($loanTypes);

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>