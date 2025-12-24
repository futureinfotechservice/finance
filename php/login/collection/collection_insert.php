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
    if (!isset($_POST['companyid']) || !isset($_POST['loanid']) || !isset($_POST['paymentdata'])) {
        $response["message"] = "Required fields missing";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $loanid = mysqli_real_escape_string($conn, $_POST['loanid']);
    $collectiondate = isset($_POST['collectiondate']) ? mysqli_real_escape_string($conn, $_POST['collectiondate']) : date('Y-m-d');
    $paymentmode = isset($_POST['paymentmode']) ? mysqli_real_escape_string($conn, $_POST['paymentmode']) : 'Cash';
    $collectedby = isset($_POST['collectedby']) ? mysqli_real_escape_string($conn, $_POST['collectedby']) : '';
    $paymentdata = json_decode($_POST['paymentdata'], true);
    
    if (!is_array($paymentdata)) {
        $response["message"] = "Invalid payment data";
        echo json_encode($response);
        exit();
    }
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        $totalCollection = 0;
        $totalPenalty = 0;
        $lastDueno = 0;
        
        // Get loan details for fixed penalty amount
        $loanSql = "SELECT lt.penaltyamount as fixed_penalty_amount 
                   FROM loanmaster l
                   LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                   WHERE l.id = '$loanid' AND l.companyid = '$companyid'";
        $loanResult = mysqli_query($conn, $loanSql);
        $loanData = mysqli_fetch_assoc($loanResult);
        $fixedPenalty = (float)$loanData['fixed_penalty_amount'];
        
        // Get max due number for the loan
        $maxDueSql = "SELECT MAX(dueno) as max_dueno FROM loanschedule 
                     WHERE loanid = '$loanid' AND companyid = '$companyid'";
        $maxDueResult = mysqli_query($conn, $maxDueSql);
        $maxDueData = mysqli_fetch_assoc($maxDueResult);
        $lastDueno = (int)$maxDueData['max_dueno'];
        
        // Process each payment
        foreach ($paymentdata as $payment) {
            $dueno = mysqli_real_escape_string($conn, $payment['dueno']);
            $dueamount = mysqli_real_escape_string($conn, $payment['dueamount']);
            $penaltyamount = mysqli_real_escape_string($conn, $payment['penaltyamount']);
            
            // Get payment details
            $paymentSql = "SELECT * FROM loanschedule 
                          WHERE loanid = '$loanid' 
                          AND companyid = '$companyid' 
                          AND dueno = '$dueno'";
            $paymentResult = mysqli_query($conn, $paymentSql);
            $paymentDetails = mysqli_fetch_assoc($paymentResult);
            
            if (isset($payment['selected']) && $payment['selected'] == true) {
                // SUCCESS PAYMENT (Paid with due amount)
                
                // Check if payment is overdue
                $isOverdue = false;
                if ($paymentDetails['duedate'] && $collectiondate > $paymentDetails['duedate']) {
                    $isOverdue = true;
                }
                
                // If paid (even if overdue), NO PENALTY charged
                $actualPenalty = 0;
                $paidAmount = $dueamount; // Store the paid amount
                
                // Update schedule as Paid with paidamount
                $updateSql = "UPDATE loanschedule 
                             SET status = 'Paid', 
                                 paidamount = '$paidAmount', 
                                 penaltypaid = '$actualPenalty',
                                 collectiondate = '$collectiondate',
                                 paymentmode = '$paymentmode',
                                 collectedby = '$collectedby'
                             WHERE loanid = '$loanid' 
                             AND companyid = '$companyid' 
                             AND dueno = '$dueno'";
                
                if (!mysqli_query($conn, $updateSql)) {
                    throw new Exception("Failed to update schedule: " . mysqli_error($conn));
                }
                
                $totalCollection += $dueamount;
                // No penalty for success payments
                
            } else if (isset($payment['unpaid']) && $payment['unpaid'] == true) {
                // UNPAID (Only penalty collected if overdue, due amount jumps to last EMI)
                
                // Check if payment is overdue
                $isOverdue = false;
                if ($paymentDetails['duedate'] && $collectiondate > $paymentDetails['duedate']) {
                    $isOverdue = true;
                }
                
                // Charge fixed penalty ONLY if overdue
                $actualPenalty = $isOverdue ? $fixedPenalty : 0;
                $paidAmount = 0; // No amount paid for unpaid
                
                if ($isOverdue) {
                    // Create a new schedule entry at the end for the unpaid amount
                    $newDueno = $lastDueno + 1;
                    
                    // Calculate new due date (next week from original due date)
                    $originalDueDate = $paymentDetails['duedate'];
                    $newDueDate = date('Y-m-d', strtotime($originalDueDate . ' +7 days'));
                    
                    // Insert new schedule entry for unpaid amount
                    $insertScheduleSql = "INSERT INTO loanschedule 
                                         (loanid, companyid, dueno, duedate, dueamount, status) 
                                         VALUES ('$loanid', '$companyid', '$newDueno', 
                                                 '$newDueDate', '$dueamount', 'Pending')";
                    
                    if (!mysqli_query($conn, $insertScheduleSql)) {
                        throw new Exception("Failed to create new schedule: " . mysqli_error($conn));
                    }
                    
                    // Update last due number
                    $lastDueno = $newDueno;
                }
                
                // Update current schedule
                $status = $isOverdue ? 'Unpaid' : 'Pending';
                $updateSql = "UPDATE loanschedule 
                             SET status = '$status', 
                                 paidamount = '$paidAmount', 
                                 penaltypaid = '$actualPenalty',
                                 collectiondate = '$collectiondate',
                                 paymentmode = '$paymentmode',
                                 collectedby = '$collectedby'
                             WHERE loanid = '$loanid' 
                             AND companyid = '$companyid' 
                             AND dueno = '$dueno'";
                
                if (!mysqli_query($conn, $updateSql)) {
                    throw new Exception("Failed to update schedule: " . mysqli_error($conn));
                }
                
                $totalPenalty += $actualPenalty;
                // No due amount collected for unpaid payments
            }
        }
        
        // Check if all payments are complete
        $checkCompleteSql = "SELECT COUNT(*) as pending FROM loanschedule 
                            WHERE loanid = '$loanid' 
                            AND companyid = '$companyid' 
                            AND status = 'Pending'";
        
        $checkResult = mysqli_query($conn, $checkCompleteSql);
        $checkRow = mysqli_fetch_assoc($checkResult);
        
        if ($checkRow['pending'] == 0) {
            // Update loan status to Completed
            $updateLoanSql = "UPDATE loanmaster SET loanstatus = 'Completed' 
                             WHERE id = '$loanid' AND companyid = '$companyid'";
            
            if (!mysqli_query($conn, $updateLoanSql)) {
                throw new Exception("Failed to update loan status: " . mysqli_error($conn));
            }
        }
        
        // Insert collection record
        $collectionNoQuery = "SELECT MAX(CAST(SUBSTRING(collectionno, 4) AS UNSIGNED)) as max_num 
                             FROM collectionmaster WHERE companyid = '$companyid'";
        $collectionNoResult = mysqli_query($conn, $collectionNoQuery);
        $maxNum = 0;
        if ($row = mysqli_fetch_assoc($collectionNoResult)) {
            $maxNum = $row['max_num'] ?: 0;
        }
        $collectionNo = 'COL' . str_pad($maxNum + 1, 5, '0', STR_PAD_LEFT);
        
        $insertCollectionSql = "INSERT INTO collectionmaster 
                               (collectionno, loanid, companyid, collectiondate, 
                                totalamount, totalpenalty, paymentmode, collectedby) 
                               VALUES ('$collectionNo', '$loanid', '$companyid', 
                                       '$collectiondate', '$totalCollection', 
                                       '$totalPenalty', '$paymentmode', '$collectedby')";
        
        if (!mysqli_query($conn, $insertCollectionSql)) {
            throw new Exception("Failed to insert collection: " . mysqli_error($conn));
        }
        
        $collectionid = mysqli_insert_id($conn);
        
        // Commit transaction
        mysqli_commit($conn);
        
        $response["status"] = "success";
        $response["message"] = "Collection recorded successfully";
        $response["collectionno"] = $collectionNo;
        $response["collectionid"] = $collectionid;
        $response["total_amount"] = $totalCollection;
        $response["total_penalty"] = $totalPenalty;
        $response["new_schedule_created"] = ($lastDueno > $maxDueData['max_dueno']);
        
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
