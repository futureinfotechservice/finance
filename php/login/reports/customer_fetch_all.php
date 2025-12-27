<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error", 
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

$response = ["status" => "error", "message" => "Unknown error"];

try {
    // Check if required parameters are provided
    if (!isset($_POST['companyid'])) {
        $response["message"] = "Company ID is required";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    
    error_log("Fetching customers for company: $companyid");

    // Fetch all active customers
    $sql = "SELECT 
                id,
                companyid,
                customername,
                gst_no,
                address,
                area,
                areaid,
                mobile1,
                mobile2,
                refer,
                refercontact,
                spousename,
                spousecontact,
                aadharurl,
                photourl,
                addedby,
                activestatus
            FROM customermaster 
            WHERE companyid = '$companyid'
            AND activestatus = '1'
            ORDER BY customername ASC";
    
    error_log("Customer SQL: $sql");
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        $response["message"] = "Query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    $customers = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        // Format customer data
        $customer = [
            'id' => $row['id'],
            'companyid' => $row['companyid'],
            'customername' => $row['customername'] ?? '',
            'gst_no' => $row['gst_no'] ?? '',
            'address' => $row['address'] ?? '',
            'area' => $row['area'] ?? '',
            'areaid' => $row['areaid'] ?? '',
            'mobile1' => $row['mobile1'] ?? '',
            'mobile2' => $row['mobile2'] ?? '',
            'refer' => $row['refer'] ?? '',
            'refercontact' => $row['refercontact'] ?? '',
            'spousename' => $row['spousename'] ?? '',
            'spousecontact' => $row['spousecontact'] ?? '',
            'aadharurl' => $row['aadharurl'] ?? '',
            'photourl' => $row['photourl'] ?? '',
            'addedby' => $row['addedby'] ?? '',
            'activestatus' => $row['activestatus'] ?? '',
            // 'createddate' => $row['createddate'] ?? '',
            'display' => $row['customername'] . ' (' . $row['mobile1'] . ')'
        ];
        
        $customers[] = $customer;
    }
    
    $response["status"] = "success";
    $response["message"] = "Customers fetched successfully";
    $response["customers"] = $customers;
    $response["total"] = count($customers);
    
    error_log("Found " . count($customers) . " active customers");

} catch (Exception $e) {
    error_log("Exception in customer_fetch_all.php: " . $e->getMessage());
    $response["message"] = "Server error: " . $e->getMessage();
}

echo json_encode($response);
mysqli_close($conn);
?>