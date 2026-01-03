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
    $paymentAccountId = isset($_POST['paymentAccountId']) ? mysqli_real_escape_string($conn, $_POST['paymentAccountId']) : '';
    
    // Check if schedule data is provided
    $scheduleData = isset($_POST['schedule']) ? json_decode($_POST['schedule'], true) : null;
    
    // Validate payment account selection (if payment mode is not Cash)
    if (empty($paymentAccountId) && $paymentmode != 'Cash') {
        $response["message"] = "Payment account is required for non-cash payment modes";
        echo json_encode($response);
        exit();
    }
    
    // Check account balance if payment account is selected
    if (!empty($paymentAccountId)) {
        // Get current account balance
        $balanceQuery = "
            SELECT 
                COALESCE(a.opening, 0) as opening,
                COALESCE(SUM(r.amount), 0) as total_receipts,
                COALESCE(SUM(p.amount), 0) as total_payments
            FROM acledger a
            LEFT JOIN receipt_entry r ON r.receipt_from_id = a.id AND r.companyid = a.companyid
            LEFT JOIN payment_entry p ON p.payment_account_id = a.id AND p.companyid = a.companyid
            WHERE a.id = '$paymentAccountId' AND a.companyid = '$companyid'
        ";
        
        $balanceResult = mysqli_query($conn, $balanceQuery);
        if ($balanceResult && $row = mysqli_fetch_assoc($balanceResult)) {
            $opening = floatval($row['opening']);
            $totalReceipts = floatval($row['total_receipts']);
            $totalPayments = floatval($row['total_payments']);
            $currentBalance = $opening + $totalReceipts - $totalPayments;
            
            // Check if sufficient balance exists
            if ($givenamount > $currentBalance) {
                $response["message"] = "Insufficient balance in payment account. Available: ₹" . number_format($currentBalance, 2) . ", Required: ₹" . number_format($givenamount, 2);
                echo json_encode($response);
                exit();
            }
        } else {
            $response["message"] = "Unable to retrieve payment account balance";
            echo json_encode($response);
            exit();
        }
    }
    
    // Get loan number
    $loanNoQuery = "SELECT MAX(CAST(SUBSTRING(loanno, 5) AS UNSIGNED)) as max_num FROM loanmaster WHERE companyid = '$companyid'";
    $loanNoResult = mysqli_query($conn, $loanNoQuery);
    $maxNum = 0;
    if ($row = mysqli_fetch_assoc($loanNoResult)) {
        $maxNum = $row['max_num'] ?: 0;
    }
    $loanNo = 'LON' . str_pad($maxNum + 1, 5, '0', STR_PAD_LEFT);
    
    // Get customer name for description
    $customerQuery = "SELECT customername FROM customermaster WHERE id = '$customerid' AND companyid = '$companyid'";
    $customerResult = mysqli_query($conn, $customerQuery);
    $customerName = "Customer";
    if ($customerResult && $row = mysqli_fetch_assoc($customerResult)) {
        $customerName = $row['customername'];
    }
    
    // Get payment account name for description
    $accountName = $paymentmode; // Default to payment mode
    if (!empty($paymentAccountId)) {
        $accountQuery = "SELECT ledgername FROM acledger WHERE id = '$paymentAccountId' AND companyid = '$companyid'";
        $accountResult = mysqli_query($conn, $accountQuery);
        if ($accountResult && $row = mysqli_fetch_assoc($accountResult)) {
            $accountName = $row['ledgername'];
        }
    }
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Insert loan
        $sql = "INSERT INTO loanmaster 
                (loanno, companyid, customerid, loantypeid, loanamount, givenamount, 
                 interestamount, loanday, noofweeks, paymentmode, startdate, 
                 addedby, loanstatus, penaltyamount, payment_account_id) 
                VALUES ('$loanNo', '$companyid', '$customerid', '$loantypeid', '$loanamount', 
                        '$givenamount', '$interestamount', '$loanday', '$noofweeks', 
                        '$paymentmode', '$startdate', '$addedby', '$loanstatus', '$penaltyamount', 
                        " . (!empty($paymentAccountId) ? "'$paymentAccountId'" : "NULL") . ")";
        
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
        
        // Record payment entry if payment account is selected
        if (!empty($paymentAccountId)) {
            // Get last serial number for this company with format PYM-0001
            $serialQuery = "SELECT serial_no FROM payment_entry 
                           WHERE companyid = '$companyid' 
                           AND serial_no LIKE 'PYM-%' 
                           ORDER BY id DESC LIMIT 1";
            
            $serialResult = mysqli_query($conn, $serialQuery);
            $serialNo = "PYM-0001"; // Default to PYM-0001 if no records exist
            
            if ($serialResult && $row = mysqli_fetch_assoc($serialResult)) {
                $lastSerial = $row['serial_no'];
                if (!empty($lastSerial) && preg_match('/PYM-(\d+)/', $lastSerial, $matches)) {
                    $lastNumber = intval($matches[1]);
                    $nextNumber = $lastNumber + 1;
                    $serialNo = "PYM-" . str_pad($nextNumber, 4, '0', STR_PAD_LEFT);
                }
            }
            
            $paymentDate = date('Y-m-d');
            $description = "Loan issued to " . mysqli_real_escape_string($conn, $customerName) . 
                          " (Loan No: $loanNo)";
            
            $paymentQuery = "INSERT INTO payment_entry 
                            (companyid, serial_no, date, payment_account, payment_account_id, 
                             cash_bank, amount, description, addedby) 
                            VALUES ('$companyid', '$serialNo', '$paymentDate', 
                            '" . mysqli_real_escape_string($conn, $accountName) . "', 
                            '$paymentAccountId', '$paymentmode', '$givenamount', 
                            '" . mysqli_real_escape_string($conn, $description) . "', 
                            '$addedby')";
            
            if (!mysqli_query($conn, $paymentQuery)) {
                throw new Exception("Failed to record payment: " . mysqli_error($conn));
            }
            
            $paymentEntryId = mysqli_insert_id($conn);
            
            // Record transaction in transaction log for better tracking
            $transactionQuery = "INSERT INTO transaction_log 
                                (companyid, date, account_id, transaction_type, 
                                 amount, reference_no, description, addedby, payment_entry_id) 
                                VALUES ('$companyid', '$paymentDate', '$paymentAccountId', 
                                'Loan Disbursement', '-$givenamount', '$loanNo', 
                                '" . mysqli_real_escape_string($conn, $description) . "', 
                                '$addedby', '$paymentEntryId')";
            
            mysqli_query($conn, $transactionQuery);
            
            // Update response with serial number info
            $response["payment_serial_no"] = $serialNo;
            $response["payment_entry_id"] = $paymentEntryId;
        }
        
        // Commit transaction
        mysqli_commit($conn);
        
        $response["status"] = "success";
        $response["message"] = "Loan issued successfully with payment schedule";
        $response["loanno"] = $loanNo;
        $response["loanid"] = $loanid;
        $response["schedule_count"] = $scheduleData ? count($scheduleData) : $noofweeks;
        $response["payment_recorded"] = !empty($paymentAccountId) ? "yes" : "no";
        
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