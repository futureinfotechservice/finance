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
    $penaltyamount = isset($_POST['penaltyamount']) ? mysqli_real_escape_string($conn, $_POST['penaltyamount']) : '0';
    $paymentmode = isset($_POST['paymentmode']) ? mysqli_real_escape_string($conn, $_POST['paymentmode']) : 'Cash';
    $startdate = isset($_POST['startdate']) ? mysqli_real_escape_string($conn, $_POST['startdate']) : date('Y-m-d');
    $addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
    $loanstatus = isset($_POST['loanstatus']) ? mysqli_real_escape_string($conn, $_POST['loanstatus']) : 'Active';
    
    // Check if schedule data is provided
    $scheduleData = isset($_POST['schedule']) ? json_decode($_POST['schedule'], true) : null;
    
    // Get loan number
    $loanNoQuery = "SELECT MAX(CAST(SUBSTRING(loanno, 5) AS UNSIGNED)) as max_num FROM loanmaster WHERE companyid = '$companyid'";
    $loanNoResult = mysqli_query($conn, $loanNoQuery);
    $maxNum = 0;
    if ($row = mysqli_fetch_assoc($loanNoResult)) {
        $maxNum = $row['max_num'] ?: 0;
    }
    $loanNo = 'LON' . str_pad($maxNum + 1, 5, '0', STR_PAD_LEFT);
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Insert loan
        $sql = "INSERT INTO loanmaster 
                (loanno, companyid, customerid, loantypeid, loanamount, givenamount, 
                 interestamount, loanday, noofweeks, paymentmode, startdate, 
                 addedby, loanstatus, penaltyamount) 
                VALUES ('$loanNo', '$companyid', '$customerid', '$loantypeid', '$loanamount', 
                        '$givenamount', '$interestamount', '$loanday', '$noofweeks', 
                        '$paymentmode', '$startdate', '$addedby', '$loanstatus','$penaltyamount')";
        
        if (!mysqli_query($conn, $sql)) {
            throw new Exception("Failed to insert loan: " . mysqli_error($conn));
        }
        
        $loanid = mysqli_insert_id($conn);
        
        // Insert payment schedule
        if ($scheduleData && is_array($scheduleData)) {
            // Use the schedule data from Flutter
            foreach ($scheduleData as $item) {
                $dueno = mysqli_real_escape_string($conn, $item['dueNo']);
                $duedate = mysqli_real_escape_string($conn, $item['dueDate']);
                $dueamount = mysqli_real_escape_string($conn, $item['dueAmount']);
                $status = mysqli_real_escape_string($conn, 'Pending'); // Default status
                
                $insertSchedule = "INSERT INTO loanschedule 
                                  (loanid, companyid, dueno, duedate, dueamount, status) 
                                  VALUES ('$loanid', '$companyid', '$dueno', '$duedate', '$dueamount', '$status')";
                
                if (!mysqli_query($conn, $insertSchedule)) {
                    throw new Exception("Failed to insert schedule: " . mysqli_error($conn));
                }
            }
        } else {
            // Fallback: Generate schedule based on weeks (existing logic)
            if ($noofweeks > 0 && $loanamount > 0) {
                $weeklyAmount = $loanamount / $noofweeks;
                $dueDate = $startdate;
                
                for ($i = 1; $i <= $noofweeks; $i++) {
                    // Calculate next due date
                    if ($i == 1) {
                        // First due date should be one week from start date
                        $dueDate = date('Y-m-d', strtotime($startdate . ' +7 days'));
                    } else {
                        $dueDate = date('Y-m-d', strtotime($dueDate . ' +7 days'));
                    }
                    
                    $insertSchedule = "INSERT INTO loanschedule 
                                      (loanid, companyid, dueno, duedate, dueamount, status) 
                                      VALUES ('$loanid', '$companyid', '$i', '$dueDate', '$weeklyAmount', 'Pending')";
                    
                    if (!mysqli_query($conn, $insertSchedule)) {
                        throw new Exception("Failed to insert schedule: " . mysqli_error($conn));
                    }
                }
            }
        }
        
        // Commit transaction
        mysqli_commit($conn);
        
        $response["status"] = "success";
        $response["message"] = "Loan issued successfully with payment schedule";
        $response["loanno"] = $loanNo;
        $response["loanid"] = $loanid;
        $response["schedule_count"] = $scheduleData ? count($scheduleData) : $noofweeks;
        
    } catch (Exception $e) {
        // Rollback transaction on error
        mysqli_rollback($conn);
        throw $e;
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>