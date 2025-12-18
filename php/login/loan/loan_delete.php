<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$response = ["status" => "error", "message" => "Unknown error"];

try {
    $loanid = mysqli_real_escape_string($conn, $_POST['loanid']);
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    // Check if loan exists
    $checkSql = "SELECT * FROM loanmaster WHERE id = '$loanid' AND companyid = '$companyid'";
    $checkResult = mysqli_query($conn, $checkSql);
    
    if (mysqli_num_rows($checkResult) == 0) {
        $response["message"] = "Loan not found";
        echo json_encode($response);
        exit();
    }
    
    // Delete schedule first
    $deleteSchedule = "DELETE FROM loanschedule WHERE loanid = '$loanid' AND companyid = '$companyid'";
    mysqli_query($conn, $deleteSchedule);
    
    // Delete loan
    $deleteLoan = "DELETE FROM loanmaster WHERE id = '$loanid' AND companyid = '$companyid'";
    
    if (mysqli_query($conn, $deleteLoan)) {
        $response["status"] = "success";
        $response["message"] = "Loan deleted successfully";
    } else {
        $response["message"] = "Failed to delete loan: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>