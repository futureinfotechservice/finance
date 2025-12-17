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
    $ledgername = mysqli_real_escape_string($conn, $_POST['ledgername'] ?? '');
    $groupname = mysqli_real_escape_string($conn, $_POST['groupname'] ?? '');
    $opening = mysqli_real_escape_string($conn, $_POST['opening'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');

    if (empty($companyid) || empty($ledgername) || empty($groupname)) {
        throw new Exception("Required fields are missing");
    }

    // Check if ledger already exists
    $checkSql = "SELECT * FROM acledger WHERE ledgername = '$ledgername' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) > 0) {
        throw new Exception("Ledger already exists");
    }

    // Insert ledger
    $sql = "INSERT INTO acledger 
            (companyid, ledgername, groupname, opening, addedby) 
            VALUES ('$companyid', '$ledgername', '$groupname', '$opening', '$addedby')";

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Ledger created successfully";
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