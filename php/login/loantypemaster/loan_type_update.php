<?php
// loan_type_update.php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Initialize response array
$response = ["status" => "error", "message" => ""];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    // Get POST data
    $loantypeid = isset($_POST['loantypeid']) ? mysqli_real_escape_string($conn, $_POST['loantypeid']) : '';
    $companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
    $loantype = isset($_POST['loantype']) ? mysqli_real_escape_string($conn, $_POST['loantype']) : '';
    $collectionday = isset($_POST['collectionday']) ? mysqli_real_escape_string($conn, $_POST['collectionday']) : '';
    $penaltyamount = isset($_POST['penaltyamount']) ? mysqli_real_escape_string($conn, $_POST['penaltyamount']) : '';
    $noofweeks = isset($_POST['noofweeks']) ? mysqli_real_escape_string($conn, $_POST['noofweeks']) : '';
    $addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

    // Log received data for debugging
    error_log("Update Request: loantypeid=$loantypeid, companyid=$companyid, loantype=$loantype, collectionday=$collectionday, penaltyamount=$penaltyamount, noofweeks=$noofweeks, addedby=$addedby");

    // Validate required fields
    if (empty($loantypeid) || empty($companyid) || empty($loantype) || empty($collectionday) || empty($noofweeks)) {
        throw new Exception("Required fields are missing");
    }

    // Check if loan type exists
    $checkSql = "SELECT * FROM loantypemaster WHERE id = '$loantypeid' AND companyid = '$companyid'";
    $checkResult = mysqli_query($conn, $checkSql);
    
    if (!$checkResult) {
        throw new Exception("Database query error: " . mysqli_error($conn));
    }
    
    if (mysqli_num_rows($checkResult) == 0) {
        throw new Exception("Loan type not found");
    }

    // Check if loan type name already exists for another record (excluding current one)
    $duplicateCheckSql = "SELECT * FROM loantypemaster 
                         WHERE loantype = '$loantype' 
                         AND companyid = '$companyid' 
                         AND id != '$loantypeid'";
    $duplicateResult = mysqli_query($conn, $duplicateCheckSql);
    
    if (mysqli_num_rows($duplicateResult) > 0) {
        throw new Exception("Loan type name already exists");
    }

    // Clean penalty amount (set to 0 if empty)
    if (empty($penaltyamount) || $penaltyamount === '') {
        $penaltyamount = '0';
    }

    // Update loan type
    $sql = "UPDATE loantypemaster SET 
            loantype = '$loantype',
            collectionday = '$collectionday',
            penaltyamount = '$penaltyamount',
            noofweeks = '$noofweeks',
            addedby = '$addedby'
            WHERE id = '$loantypeid' AND companyid = '$companyid'";

    if (mysqli_query($conn, $sql)) {
        $affectedRows = mysqli_affected_rows($conn);
        
        if ($affectedRows > 0) {
            $response["status"] = "success";
            $response["message"] = "Loan type updated successfully";
            $response["affected_rows"] = $affectedRows;
        } else {
            // No rows affected - data might be the same
            $response["status"] = "success";
            $response["message"] = "No changes made (data already up to date)";
            $response["affected_rows"] = 0;
        }
    } else {
        throw new Exception("Database update error: " . mysqli_error($conn));
    }

} catch (Exception $e) {
    $response["message"] = $e->getMessage();
    error_log("Update Error: " . $e->getMessage());
}

// Always output valid JSON
echo json_encode($response);

// Close connection
if ($conn) {
    mysqli_close($conn);
}

// Ensure no additional output
exit();
?>