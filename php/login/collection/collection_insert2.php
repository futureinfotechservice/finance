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
        $lastDueDate = null;
        $newScheduleCreated = false;
        
        // Get loan details for fixed penalty amount
        $loanSql = "SELECT 
                   lt.penaltyamount as fixed_penalty_amount
                   FROM loanmaster l
                   LEFT JOIN loantypemaster lt ON l.loantypeid = lt.id
                   WHERE l.id = '$loanid' AND l.companyid = '$companyid'";
        $loanResult = mysqli_query($conn, $loanSql);
        $loanData = mysqli_fetch_assoc($loanResult);
        $fixedPenalty = (float)$loanData['fixed_penalty_amount'];
        
        // Get max due number and last due date for the loan
        $maxDueSql = "SELECT MAX(dueno) as max_dueno, MAX(duedate) as last_duedate 
                     FROM loanschedule 
                     WHERE loanid = '$loanid' AND companyid = '$companyid'";
        $maxDueResult = mysqli_query($conn, $maxDueSql);
        $maxDueData = mysqli_fetch_assoc($maxDueResult);
        $lastDueno = (int)$maxDueData['max_dueno'];
        $lastDueDate = $maxDueData['last_duedate'];
        
        // If no last due date, use current date
        if (!$lastDueDate) {
            $lastDueDate = $collectiondate;
        }
        
        // Function to calculate next weekday (weekly)
        function getNextWeekday($date) {
            return date('Y-m-d', strtotime($date . ' +7 days'));
        }
        
        // Track which duenos are being collected (for collectionmaster_details)
        $collectedDuenos = [];
        
        // Process each payment
        foreach ($paymentdata as $payment) {
            $dueno = mysqli_real_escape_string($conn, $payment['dueno']);
            $dueamount = (float)mysqli_real_escape_string($conn, $payment['dueamount']);
            $paidamount = (float)mysqli_real_escape_string($conn, $payment['paidamount'] ?? '0');
            $penaltyamount = (float)mysqli_real_escape_string($conn, $payment['penaltyamount']);
            $due_received = (float)mysqli_real_escape_string($conn, $payment['due_received'] ?? '0');
            $penalty_received = (float)mysqli_real_escape_string($conn, $payment['penalty_received'] ?? '0');
            
            // Get payment details including already received penalty and current status
            $paymentSql = "SELECT * FROM loanschedule 
                          WHERE loanid = '$loanid' 
                          AND companyid = '$companyid' 
                          AND dueno = '$dueno'";
            $paymentResult = mysqli_query($conn, $paymentSql);
            $paymentDetails = mysqli_fetch_assoc($paymentResult);
            
            // Get current status and received amounts
            $currentStatus = $paymentDetails['status'] ?? 'Pending';
            $alreadyReceivedPenalty = (float)($paymentDetails['penalty_received'] ?? 0);
            $alreadyReceivedDue = (float)($paymentDetails['due_received'] ?? 0);
            
            if (isset($payment['selected']) && $payment['selected'] == true) {
                // SUCCESS PAYMENT (Paid with due amount)
                
                // IMPORTANT: Check if ANY penalty has been paid already (partial or full)
                if ($alreadyReceivedPenalty > 0) {
                    throw new Exception("Cannot collect due amount on EMI $dueno. Penalty (₹$alreadyReceivedPenalty) has already been paid. You can only collect remaining penalty.");
                }
                
                // Additional check: If current status is 'Partially Paid Penalty' or 'Penalty Paid'
                if ($currentStatus == 'Partially Paid Penalty' || $currentStatus == 'Penalty Paid') {
                    throw new Exception("Cannot collect due amount on EMI $dueno. Penalty collection has already started. Current status: $currentStatus");
                }
                
                // Check if partial due amount is already paid
                if ($alreadyReceivedDue > 0) {
                    // This is a partial payment, continue with it
                }
                
                // Check if payment is overdue
                $isOverdue = false;
                if ($paymentDetails['duedate'] && $collectiondate > $paymentDetails['duedate']) {
                    $isOverdue = true;
                }
                
                // Rule 7: NO PENALTY charged for success payments
                $actualPenalty = 0;
                $penalty_received = 0;
                
                // Calculate current received amounts
                $currentDueReceived = (float)($paymentDetails['due_received'] ?? 0);
                $newDueReceived = $currentDueReceived + $due_received;
                
                // Check if payment is fully received
                $isFullyPaid = ($newDueReceived >= $dueamount);
                
                // Update schedule
                $updateSql = "UPDATE loanschedule 
                             SET status = '" . ($isFullyPaid ? 'Paid' : 'Partially Paid') . "', 
                                 paidamount = paidamount + '$due_received',
                                 due_received = due_received + '$due_received',
                                 penaltypaid = penaltypaid + '$actualPenalty',
                                 penalty_received = penalty_received + '$penalty_received',
                                 collectiondate = '$collectiondate',
                                 paymentmode = '$paymentmode',
                                 collectedby = '$collectedby'
                             WHERE loanid = '$loanid' 
                             AND companyid = '$companyid' 
                             AND dueno = '$dueno'";
                
                if (!mysqli_query($conn, $updateSql)) {
                    throw new Exception("Failed to update schedule: " . mysqli_error($conn));
                }
                
                $totalCollection += $due_received;
                $collectedDuenos[] = [
                    'dueno' => $dueno,
                    'due_received' => $due_received,
                    'penalty_received' => $penalty_received,
                    'payment_type' => 'paid'
                ];
                
            } else if (isset($payment['unpaid']) && $payment['unpaid'] == true) {
                // UNPAID (Only penalty collected, due amount jumps to last EMI)
                
                // IMPORTANT: Check if ANY due amount has been paid already (partial or full)
                if ($alreadyReceivedDue > 0) {
                    throw new Exception("Cannot collect penalty on EMI $dueno. Partial due amount (₹$alreadyReceivedDue) already paid.");
                }
                
                // Additional check: If current status is 'Partially Paid' or 'Paid'
                if ($currentStatus == 'Partially Paid' || $currentStatus == 'Paid') {
                    throw new Exception("Cannot collect penalty on EMI $dueno. Due amount collection has already started. Current status: $currentStatus");
                }
		
                
                // Check if payment is overdue
                $isOverdue = false;
                if ($paymentDetails['duedate'] && $collectiondate > $paymentDetails['duedate']) {
                    $isOverdue = true;
                }
                
                // Check if trying to collect penalty on non-overdue payment
                if (!$isOverdue && $penalty_received > 0) {
                    throw new Exception("Cannot collect penalty on EMI $dueno. It is not overdue.");
                }
                
                // Use editable penalty_received amount (can be 0)
                $actualPenalty = $penalty_received;
                
                // Calculate current received amounts
                $currentPenaltyReceived = (float)($paymentDetails['penalty_received'] ?? 0);
                $newPenaltyReceived = $currentPenaltyReceived + $penalty_received;
                
                // Check if penalty is fully received
                $isPenaltyFullyPaid = ($newPenaltyReceived >= $fixedPenalty);
                
                // DECISION: Should we create new EMI?
                // Only create new EMI if NO penalty has been collected yet AND no due amount has been collected
                $shouldCreateNewEMI = ($currentPenaltyReceived == 0 && $alreadyReceivedDue == 0 && $currentStatus != 'Partially Paid Penalty');
                
                $newDueno = null;
                $newDueDate = null;
                
                if ($shouldCreateNewEMI) {
                    // Calculate next weekday from last due date
                    $newDueDate = getNextWeekday($lastDueDate);
                    
                    // Create a new schedule entry at the end for the unpaid amount
                    $newDueno = $lastDueno + 1;
                    
                    // Insert new schedule entry for unpaid amount with next weekday date
                    $insertScheduleSql = "INSERT INTO loanschedule 
                                         (loanid, companyid, dueno, duedate, dueamount, status) 
                                         VALUES ('$loanid', '$companyid', '$newDueno', 
                                                 '$newDueDate', '$dueamount', 'Pending')";
                    
                    if (!mysqli_query($conn, $insertScheduleSql)) {
                        throw new Exception("Failed to create new schedule: " . mysqli_error($conn));
                    }
                    
                    // Update last due number and date for next iteration
                    $lastDueno = $newDueno;
                    $lastDueDate = $newDueDate;
                    $newScheduleCreated = true;
                    
                    $createdNewEMI = true;
                } else {
                    $createdNewEMI = false;
                }
                
                // Update current schedule
                // If penalty has been partially paid before, keep status as 'Partially Paid Penalty'
                if ($isPenaltyFullyPaid) {
                    $status = 'Penalty Paid';
                } else if ($currentPenaltyReceived > 0 || $penalty_received > 0 || $penalty_received == 0) {
                    // If already had partial penalty OR collecting penalty now, mark as 'Partially Paid Penalty'
                    $status = 'Partially Paid Penalty';
                } else {
                    $status = 'Unpaid';
                }
                
                $updateSql = "UPDATE loanschedule 
                             SET status = '$status', 
                                 paidamount = paidamount + '0',  
                                 due_received = due_received + '0',
                                 penaltypaid = penaltypaid + '$actualPenalty',
                                 penalty_received = penalty_received + '$penalty_received',
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
                $collectedDuenos[] = [
                    'dueno' => $dueno,
                    'due_received' => 0,
                    'penalty_received' => $penalty_received,
                    'created_new_emi' => $createdNewEMI, // Only true if no penalty was collected before
                    'new_emi_dueno' => $newDueno,
                    'new_emi_date' => $newDueDate,
                    'payment_type' => 'unpaid',
                    'already_had_penalty' => ($currentPenaltyReceived > 0)
                ];
            }
        }
        
        // Check if all payments are complete
        $checkCompleteSql = "SELECT COUNT(*) as pending FROM loanschedule 
                            WHERE loanid = '$loanid' 
                            AND companyid = '$companyid' 
                            AND status IN ('Pending', 'Partially Paid', 'Partially Paid Penalty', 'Unpaid')";
        
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
        
        // Insert collection record - CORRECTED: Use due_received_total and penalty_received_total
        $insertCollectionSql = "INSERT INTO collectionmaster 
                               (collectionno, loanid, companyid, collectiondate, 
                                totalamount, due_received_total, penalty_received_total, 
                                totalpenalty, paymentmode, collectedby) 
                               VALUES ('$collectionNo', '$loanid', '$companyid', 
                                       '$collectiondate', 
                                       '" . ($totalCollection + $totalPenalty) . "', 
                                       '$totalCollection', 
                                       '$totalPenalty',
                                       '$totalPenalty', 
                                       '$paymentmode', 
                                       '$collectedby')";
        
        if (!mysqli_query($conn, $insertCollectionSql)) {
            throw new Exception("Failed to insert collection: " . mysqli_error($conn));
        }
        
        $collectionid = mysqli_insert_id($conn);
        
        // Insert collection details (for each dueno)
        foreach ($collectedDuenos as $duenoData) {
            $dueno = mysqli_real_escape_string($conn, $duenoData['dueno']);
            $dueReceived = $duenoData['due_received'];
            $penaltyReceived = $duenoData['penalty_received'];
            
            $insertDetailSql = "INSERT INTO collectionmaster_details 
                               (collectionid, dueno, due_received, penalty_received) 
                               VALUES ('$collectionid', '$dueno', '$dueReceived', '$penaltyReceived')";
            
            if (!mysqli_query($conn, $insertDetailSql)) {
                throw new Exception("Failed to insert collection details: " . mysqli_error($conn));
            }
        }
        
        // Commit transaction
        mysqli_commit($conn);
        
        $response["status"] = "success";
        $response["message"] = "Collection recorded successfully";
        $response["collectionno"] = $collectionNo;
        $response["collectionid"] = $collectionid;
        $response["total_amount"] = $totalCollection + $totalPenalty;
        $response["due_received_total"] = $totalCollection;
        $response["penalty_received_total"] = $totalPenalty;
        $response["new_schedule_created"] = $newScheduleCreated;
        $response["last_dueno"] = $lastDueno;
        $response["last_due_date"] = $lastDueDate;
        $response["collected_duenos"] = $collectedDuenos; // For debugging
        
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