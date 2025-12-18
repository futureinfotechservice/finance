<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = ["status" => "error", "message" => "Unknown error", "loanno" => ""];

try {
    // Check if companyid is provided
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $prefix = isset($_POST['prefix']) ? mysqli_real_escape_string($conn, $_POST['prefix']) : 'LON';
    
    // Get current year and month
    $currentYear = date('y');
    $currentMonth = date('m');
    
    // Method 1: Get last loan number from loanmaster
    $sql = "SELECT loanno FROM loanmaster 
            WHERE companyid = '$companyid' 
            AND loanno LIKE '$prefix%'
            ORDER BY id DESC 
            LIMIT 1";
    
    $result = mysqli_query($conn, $sql);
    
    if ($result && mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        $lastLoanNo = $row['loanno'];
        
        // Extract numeric part
        if (preg_match('/\d+/', $lastLoanNo, $matches)) {
            $lastNumber = (int)$matches[0];
            $newNumber = $lastNumber + 1;
        } else {
            $newNumber = 1;
        }
    } else {
        // No existing loans, start from 1
        $newNumber = 1;
    }
    
    // Format with leading zeros (5 digits)
    $formattedNumber = str_pad($newNumber, 5, '0', STR_PAD_LEFT);
    $newLoanNo = $prefix . $formattedNumber;
    
    // Alternative: Generate with year-month format
    // $newLoanNo = $prefix . $currentYear . $currentMonth . str_pad($newNumber, 4, '0', STR_PAD_LEFT);
    
    // Check if this loan number already exists (shouldn't happen, but just in case)
    $checkSql = "SELECT COUNT(*) as count FROM loanmaster WHERE loanno = '$newLoanNo' AND companyid = '$companyid'";
    $checkResult = mysqli_query($conn, $checkSql);
    $checkRow = mysqli_fetch_assoc($checkResult);
    
    if ($checkRow['count'] > 0) {
        // If duplicate exists, increment by 1
        $newNumber++;
        $formattedNumber = str_pad($newNumber, 5, '0', STR_PAD_LEFT);
        $newLoanNo = $prefix . $formattedNumber;
    }
    
    $response["status"] = "success";
    $response["message"] = "Loan number generated successfully";
    $response["loanno"] = $newLoanNo;

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
    // Generate a fallback loan number
    $response["loanno"] = 'LON' . date('Ymd') . rand(100, 999);
}

echo json_encode($response);
mysqli_close($conn);
?>