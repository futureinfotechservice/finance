<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $ledgerid = mysqli_real_escape_string($conn, $_POST['ledgerid'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $ledgername = mysqli_real_escape_string($conn, $_POST['ledgername'] ?? '');
    $groupname = mysqli_real_escape_string($conn, $_POST['groupname'] ?? '');
    $opening = mysqli_real_escape_string($conn, $_POST['opening'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');
    $type = mysqli_real_escape_string($conn, $_POST['type'] ?? '');

    if (empty($ledgerid) || empty($companyid) || empty($ledgername) || empty($groupname)) {
        throw new Exception("Required fields are missing");
    }
	
	
	    if (strtolower($type) == 'debit' && $opening !== '') {
        $openingValue = floatval($opening);
        if ($openingValue > 0) {
            $opening = '-' . $openingValue;
          }
        }

    // Check if ledger exists
    $checkSql = "SELECT * FROM acledger WHERE id = '$ledgerid' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($result) == 0) {
        throw new Exception("Ledger not found");
    }

    // Check if ledger name already exists for another record
    $duplicateCheckSql = "SELECT * FROM acledger 
                         WHERE ledgername = '$ledgername' 
                         AND companyid = '$companyid' 
                         AND id != '$ledgerid'";
    $duplicateResult = mysqli_query($conn, $duplicateCheckSql);
    
    if (mysqli_num_rows($duplicateResult) > 0) {
        throw new Exception("Ledger name already exists");
    }

    // Update ledger
    $sql = "UPDATE acledger SET 
            ledgername = '$ledgername',
            groupname = '$groupname',
            opening = '$opening',
            type = '$type',
            addedby = '$addedby'
            WHERE id = '$ledgerid' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        $affectedRows = mysqli_affected_rows($conn);
        
        if ($affectedRows > 0) {
            $response["status"] = "success";
            $response["message"] = "Ledger updated successfully";
        } else {
            $response["status"] = "success";
            $response["message"] = "No changes made";
        }
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