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
    // Check required fields
    if (!isset($_POST['companyid']) || !isset($_POST['loanamount']) || !isset($_POST['customerid'])) {
        $response["message"] = "Required fields missing";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $customerid = mysqli_real_escape_string($conn, $_POST['customerid']);
    $loantypeid = isset($_POST['loantypeid']) ? mysqli_real_escape_string($conn, $_POST['loantypeid']) : '';
    $loanamount = mysqli_real_escape_string($conn, $_POST['loanamount']);
    $givenamount = isset($_POST['givenamount']) ? mysqli_real_escape_string($conn, $_POST['givenamount']) : $loanamount;
    $interestamount = isset($_POST['interestamount']) ? mysqli_real_escape_string($conn, $_POST['interestamount']) : '0';
    $loanday = isset($_POST['loanday']) ? mysqli_real_escape_string($conn, $_POST['loanday']) : '';
    $noofweeks = isset($_POST['noofweeks']) ? mysqli_real_escape_string($conn, $_POST['noofweeks']) : '0';
    $paymentmode = isset($_POST['paymentmode']) ? mysqli_real_escape_string($conn, $_POST['paymentmode']) : 'Cash';
    $startdate = isset($_POST['startdate']) ? mysqli_real_escape_string($conn, $_POST['startdate']) : date('Y-m-d');
    $addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
    $loanstatus = isset($_POST['loanstatus']) ? mysqli_real_escape_string($conn, $_POST['loanstatus']) : 'Active';
    
    // Get loan number (auto increment based on last loan)
    $loanNoQuery = "SELECT MAX(CAST(SUBSTRING(loanno, 5) AS UNSIGNED)) as max_num FROM loanmaster WHERE companyid = '$companyid'";
    $loanNoResult = mysqli_query($conn, $loanNoQuery);
    $maxNum = 0;
    if ($row = mysqli_fetch_assoc($loanNoResult)) {
        $maxNum = $row['max_num'] ?: 0;
    }
    $loanNo = 'LON' . str_pad($maxNum + 1, 5, '0', STR_PAD_LEFT);
    
    // Insert loan
    $sql = "INSERT INTO loanmaster 
            (loanno, companyid, customerid, loantypeid, loanamount, givenamount, 
             interestamount, loanday, noofweeks, paymentmode, startdate, 
             addedby, loanstatus) 
            VALUES ('$loanNo', '$companyid', '$customerid', '$loantypeid', '$loanamount', 
                    '$givenamount', '$interestamount', '$loanday', '$noofweeks', 
                    '$paymentmode', '$startdate', '$addedby', '$loanstatus')";
    
    if (mysqli_query($conn, $sql)) {
        $loanid = mysqli_insert_id($conn);
        
        // Generate payment schedule
        if ($noofweeks > 0 && $loanamount > 0) {
            $weeklyAmount = $loanamount / $noofweeks;
            $dueDate = date('Y-m-d', strtotime($startdate));
            
            // Get day number (0=Sunday, 1=Monday, etc.)
            $dayNumber = array_search($loanday, ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']);
            
            for ($i = 1; $i <= $noofweeks; $i++) {
                // Calculate next due date
                $dueDate = date('Y-m-d', strtotime("next $loanday", strtotime($dueDate)));
                if ($i == 1) {
                    // First due date should be one week from start date on the specified loan day
                    $dueDate = date('Y-m-d', strtotime("next $loanday", strtotime($startdate)));
                }
                
                $insertSchedule = "INSERT INTO loanschedule 
                                  (loanid, dueno, duedate, dueamount, status, companyid) 
                                  VALUES ('$loanid', '$i', '$dueDate', '$weeklyAmount', 'Pending', '$companyid')";
                mysqli_query($conn, $insertSchedule);
            }
        }
        
        $response["status"] = "success";
        $response["message"] = "Loan issued successfully";
        $response["loanno"] = $loanNo;
        $response["loanid"] = $loanid;
    } else {
        $response["message"] = "Failed to issue loan: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>