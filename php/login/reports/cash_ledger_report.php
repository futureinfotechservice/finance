<?php
// cash_ledger_report.php (FIXED FOR COLLATION ERROR)
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = ["status" => "error", "message" => "Unknown error"];

try {
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $fromDate = isset($_POST['fromDate']) ? mysqli_real_escape_string($conn, $_POST['fromDate']) : null;
    $toDate = isset($_POST['toDate']) ? mysqli_real_escape_string($conn, $_POST['toDate']) : null;
    $ledgerId = isset($_POST['ledgerId']) ? mysqli_real_escape_string($conn, $_POST['ledgerId']) : null;
    
    // If ledgerId is provided, get that specific ledger's opening balance
    // Otherwise, get Cash ledger by default
    if ($ledgerId) {
        $ledgerSql = "SELECT id, ledgername, opening FROM acledger 
                      WHERE companyid = '$companyid' 
                      AND id = '$ledgerId' 
                      LIMIT 1";
    } else {
        $ledgerSql = "SELECT id, ledgername, opening FROM acledger 
                      WHERE companyid = '$companyid' 
                      AND ledgername like '%' 
                      LIMIT 1";
    }
    
    $ledgerResult = mysqli_query($conn, $ledgerSql);
    $ledger = mysqli_fetch_assoc($ledgerResult);
    
    if (!$ledger) {
        $response["message"] = $ledgerId ? "Ledger not found" : "Cash ledger account not found";
        echo json_encode($response);
        exit();
    }
    
    $selectedLedgerId = $ledger['id'];
    $ledgerName = $ledger['ledgername'];
    $openingBalance = (float)$ledger['opening'];
    
    // Get payment entries WHERE this ledger is the payment_account (debit from this ledger)
    $paymentSql = "SELECT 
                    pe.id,
                    pe.date,
                    pe.amount,
                    CONVERT(pe.description USING utf8) COLLATE utf8_general_ci as description,
                    'Payment' as type,
                    'debit' as entry_type,
                    CONVERT(al_pay.ledgername USING utf8) COLLATE utf8_general_ci as counterparty_name,
                    al_pay.id as counterparty_id
                   FROM payment_entry pe
                   LEFT JOIN acledger al_pay ON pe.cash_bank = al_pay.id
                   WHERE pe.companyid = '$companyid'
                     AND pe.payment_account_id = '$selectedLedgerId'";
    
    if ($fromDate) {
        $paymentSql .= " AND pe.date >= '$fromDate'";
    }
    if ($toDate) {
        $paymentSql .= " AND pe.date <= '$toDate'";
    }
    
    // Get receipt entries WHERE this ledger is the receipt_from (credit to this ledger)
    $receiptSql = "SELECT 
                    re.id,
                    re.date,
                    re.amount,
                    CONVERT(re.description USING utf8) COLLATE utf8_general_ci as description,
                    'Receipt' as type,
                    'credit' as entry_type,
                    CONVERT(al_rec.ledgername USING utf8) COLLATE utf8_general_ci as counterparty_name,
                    al_rec.id as counterparty_id
                   FROM receipt_entry re
                   LEFT JOIN acledger al_rec ON re.cash_bank = al_rec.id
                   WHERE re.companyid = '$companyid'
                     AND re.receipt_from_id = '$selectedLedgerId'";
    
    if ($fromDate) {
        $receiptSql .= " AND re.date >= '$fromDate'";
    }
    if ($toDate) {
        $receiptSql .= " AND re.date <= '$toDate'";
    }
    
    // Get opening balance entries (transfers from other ledgers to this ledger)
    $openingTransfersSql = "SELECT 
                            pe.id,
                            pe.date,
                            pe.amount,
                            CONCAT('Transfer from ', CONVERT(al_pay.ledgername USING utf8) COLLATE utf8_general_ci) as description,
                            'Transfer' as type,
                            'credit' as entry_type,
                            CONVERT(al_pay.ledgername USING utf8) COLLATE utf8_general_ci as counterparty_name,
                            al_pay.id as counterparty_id
                           FROM payment_entry pe
                           INNER JOIN acledger al_pay ON pe.payment_account_id = al_pay.id
                           WHERE pe.companyid = '$companyid'
                             AND pe.cash_bank = '$selectedLedgerId'";
    
    if ($fromDate) {
        $openingTransfersSql .= " AND pe.date >= '$fromDate'";
    }
    if ($toDate) {
        $openingTransfersSql .= " AND pe.date <= '$toDate'";
    }
    
    // Get closing balance entries (transfers from this ledger to other ledgers)
    $closingTransfersSql = "SELECT 
                            re.id,
                            re.date,
                            re.amount,
                            CONCAT('Transfer to ', CONVERT(al_rec.ledgername USING utf8) COLLATE utf8_general_ci) as description,
                            'Transfer' as type,
                            'debit' as entry_type,
                            CONVERT(al_rec.ledgername USING utf8) COLLATE utf8_general_ci as counterparty_name,
                            al_rec.id as counterparty_id
                           FROM receipt_entry re
                           INNER JOIN acledger al_rec ON re.receipt_from_id = al_rec.id
                           WHERE re.companyid = '$companyid'
                             AND re.cash_bank = '$selectedLedgerId'";
    
    if ($fromDate) {
        $closingTransfersSql .= " AND re.date >= '$fromDate'";
    }
    if ($toDate) {
        $closingTransfersSql .= " AND re.date <= '$toDate'";
    }
    
    // Combine all queries with explicit collation
    $combinedSql = "SELECT * FROM (
                        ($paymentSql) 
                        UNION ALL 
                        ($receiptSql) 
                        UNION ALL 
                        ($openingTransfersSql) 
                        UNION ALL 
                        ($closingTransfersSql)
                    ) as combined_results
                    ORDER BY date ASC, id ASC";
    
    $result = mysqli_query($conn, $combinedSql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $entries = [];
    $runningBalance = $openingBalance;
    
    // Add opening balance entry
    $entries[] = [
        'id' => 'opening',
        'date' => '',
        'description' => 'Opening Balance',
        'debit' => 0,
        'credit' => 0,
        'balance' => $openingBalance,
        'type' => 'Opening',
        'counterparty_name' => '',
        'counterparty_id' => ''
    ];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $debit = $row['entry_type'] == 'debit' ? (float)$row['amount'] : 0;
        $credit = $row['entry_type'] == 'credit' ? (float)$row['amount'] : 0;
        
        if ($row['entry_type'] == 'debit') {
            $runningBalance -= $debit; // Debit reduces ledger balance
        } else {
            $runningBalance += $credit; // Credit increases ledger balance
        }
        
        $description = $row['description'];
        if ($row['counterparty_name']) {
            $description .= " (" . $row['counterparty_name'] . ")";
        }
        
        $entries[] = [
            'id' => $row['id'],
            'date' => $row['date'],
            'description' => $description,
            'debit' => $debit,
            'credit' => $credit,
            'balance' => $runningBalance,
            'type' => $row['type'],
            'counterparty_name' => $row['counterparty_name'] ?? '',
            'counterparty_id' => $row['counterparty_id'] ?? ''
        ];
    }
    
    // Add closing balance entry
    $entries[] = [
        'id' => 'closing',
        'date' => '',
        'description' => 'Closing Balance',
        'debit' => 0,
        'credit' => 0,
        'balance' => $runningBalance,
        'type' => 'Closing',
        'counterparty_name' => '',
        'counterparty_id' => ''
    ];
    
    // Calculate totals
    $totalDebit = 0;
    $totalCredit = 0;
    
    foreach ($entries as $entry) {
        if ($entry['type'] != 'Opening' && $entry['type'] != 'Closing') {
            $totalDebit += $entry['debit'];
            $totalCredit += $entry['credit'];
        }
    }
    
    $response["status"] = "success";
    $response["message"] = "Cash ledger report fetched successfully";
    $response["entries"] = $entries;
    $response["summary"] = [
        'ledgerName' => $ledgerName,
        'openingBalance' => $openingBalance,
        'closingBalance' => $runningBalance,
        'totalDebit' => $totalDebit,
        'totalCredit' => $totalCredit,
        'totalEntries' => count($entries) - 2 // Excluding opening and closing
    ];
    
} catch (Exception $e) {
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>