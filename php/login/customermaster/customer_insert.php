<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Initialize response array
$response = ["status" => "error", "message" => "Unknown error"];

try {
    // Check if required fields are present
    if (!isset($_POST['companyid']) || !isset($_POST['customername'])) {
        $response["message"] = "Required fields missing";
        echo json_encode($response);
        exit();
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $customername = mysqli_real_escape_string($conn, $_POST['customername']);
    $gst_no = isset($_POST['gst_no']) ? mysqli_real_escape_string($conn, $_POST['gst_no']) : '';
    $address = isset($_POST['address']) ? mysqli_real_escape_string($conn, $_POST['address']) : '';
    $area = isset($_POST['area']) ? mysqli_real_escape_string($conn, $_POST['area']) : '';
    $areaid = isset($_POST['areaid']) ? mysqli_real_escape_string($conn, $_POST['areaid']) : '';
    $mobile1 = isset($_POST['mobile1']) ? mysqli_real_escape_string($conn, $_POST['mobile1']) : '';
    $mobile2 = isset($_POST['mobile2']) ? mysqli_real_escape_string($conn, $_POST['mobile2']) : '';
    $refer = isset($_POST['refer']) ? mysqli_real_escape_string($conn, $_POST['refer']) : '';
    $refercontact = isset($_POST['refercontact']) ? mysqli_real_escape_string($conn, $_POST['refercontact']) : '';
    $spousename = isset($_POST['spousename']) ? mysqli_real_escape_string($conn, $_POST['spousename']) : '';
    $spousecontact = isset($_POST['spousecontact']) ? mysqli_real_escape_string($conn, $_POST['spousecontact']) : '';
    $addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
    $activestatus = isset($_POST['activestatus']) ? mysqli_real_escape_string($conn, $_POST['activestatus']) : '1';

    // Create uploads directory if it doesn't exist
    if (!file_exists('uploads')) {
        mkdir('uploads', 0777, true);
    }
    if (!file_exists('uploads/aadhar')) {
        mkdir('uploads/aadhar', 0777, true);
    }
    if (!file_exists('uploads/photo')) {
        mkdir('uploads/photo', 0777, true);
    }

    // Check if customer already exists
    $checkSql = "SELECT * FROM customermaster WHERE customername = '$customername' AND companyid = '$companyid'";
    $result = mysqli_query($conn, $checkSql);
    
    if (!$result) {
        $response["message"] = "Database query error: " . mysqli_error($conn);
        echo json_encode($response);
        exit();
    }
    
    if (mysqli_num_rows($result) > 0) {
        $response["message"] = "Customer already exists";
        echo json_encode($response);
        exit();
    }

    // Handle file uploads
    $aadharurl = '';
    $photourl = '';

    // Upload Aadhar file
    if (isset($_FILES['aadharfile']) && $_FILES['aadharfile']['error'] == 0) {
        $aadharFileName = uniqid() . '_' . basename($_FILES['aadharfile']['name']);
        $aadharTargetPath = 'uploads/aadhar/' . $aadharFileName;
        
        if (move_uploaded_file($_FILES['aadharfile']['tmp_name'], $aadharTargetPath)) {
            $aadharurl = "https://financeapi.futureinfotechservices.in/uploads/aadhar/" . $aadharFileName;
        }
    }

    // Upload Photo file
    if (isset($_FILES['photofile']) && $_FILES['photofile']['error'] == 0) {
        $photoFileName = uniqid() . '_' . basename($_FILES['photofile']['name']);
        $photoTargetPath = 'uploads/photo/' . $photoFileName;
        
        if (move_uploaded_file($_FILES['photofile']['tmp_name'], $photoTargetPath)) {
            $photourl = "https://financeapi.futureinfotechservices.in/uploads/photo/" . $photoFileName;
        }
    }

    // Insert customer
    $sql = "INSERT INTO customermaster 
        (companyid, customername, gst_no, address, area, areaid, mobile1, mobile2, 
         refer, refercontact, spousename, spousecontact, aadharurl, photourl, 
         addedby, activestatus) 
        VALUES ('$companyid', '$customername', '$gst_no', '$address', '$area', '$areaid', 
                '$mobile1', '$mobile2', '$refer', '$refercontact', '$spousename', 
                '$spousecontact', '$aadharurl', '$photourl', '$addedby', '$activestatus')";

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Customer created successfully";
        $response["customer_id"] = mysqli_insert_id($conn);
    } else {
        $response["message"] = "Failed to create customer: " . mysqli_error($conn);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

// Always output valid JSON
echo json_encode($response);

// Close connection
mysqli_close($conn);
?>