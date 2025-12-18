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
    
    $sql = "SELECT * FROM loanschedule 
            WHERE loanid = '$loanid' AND companyid = '$companyid'
            ORDER BY dueno ASC";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        $schedule = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $schedule[] = $row;
        }
        $response["status"] = "success";
        $response["schedule"] = $schedule;
    } else {
        $response["message"] = "Error fetching schedule: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>