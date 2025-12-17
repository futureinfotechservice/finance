<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $loantype = mysqli_real_escape_string($conn, $_POST['loantype'] ?? '');
    $collectionday = mysqli_real_escape_string($conn, $_POST['collectionday'] ?? '');
    $penaltyamount = mysqli_real_escape_string($conn, $_POST['penaltyamount'] ?? '');
    $noofweeks = mysqli_real_escape_string($conn, $_POST['noofweeks'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');

    if (empty($companyid) || empty($loantype) || empty($collectionday) || empty($noofweeks)) {
        throw new Exception("Required fields are missing");
    }

    // Check if loan type already exists
    $checkSql = "SELECT * FROM loantypemaster WHERE loantype = '$loantype' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) > 0) {
        throw new Exception("Loan type already exists");
    }

    // Insert loan type
    $sql = "INSERT INTO loantypemaster 
            (companyid, loantype, collectionday, penaltyamount, noofweeks, addedby) 
            VALUES ('$companyid', '$loantype', '$collectionday', '$penaltyamount', '$noofweeks', '$addedby')";

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Loan type created successfully";
        $response["id"] = mysqli_insert_id($conn);
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