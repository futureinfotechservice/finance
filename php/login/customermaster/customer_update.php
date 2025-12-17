<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}

$customerid = $_POST['customerid'] ?? '';
$companyid = $_POST['companyid'] ?? '';
$customername = $_POST['customername'] ?? '';
$gst_no = $_POST['gst_no'] ?? '';
$address = $_POST['address'] ?? '';
$area = $_POST['area'] ?? '';
$areaid = $_POST['areaid'] ?? '';
$mobile1 = $_POST['mobile1'] ?? '';
$mobile2 = $_POST['mobile2'] ?? '';
$refer = $_POST['refer'] ?? '';
$refercontact = $_POST['refercontact'] ?? '';
$spousename = $_POST['spousename'] ?? '';
$spousecontact = $_POST['spousecontact'] ?? '';
$addedby = $_POST['addedby'] ?? '';

// Handle file uploads
$aadharurl = '';
$photourl = '';

// Get existing file URLs first
$sqlCheck = "SELECT aadharurl, photourl FROM customermaster WHERE id = ? AND companyid = ?";
$stmtCheck = $conn->prepare($sqlCheck);
$stmtCheck->bind_param("ss", $customerid, $companyid);
$stmtCheck->execute();
$resultCheck = $stmtCheck->get_result();
$existing = $resultCheck->fetch_assoc();
$stmtCheck->close();

// Upload Aadhar file if provided
if (isset($_FILES['aadharfile']) && $_FILES['aadharfile']['error'] == 0) {
    $aadharFileName = uniqid() . '_' . basename($_FILES['aadharfile']['name']);
    $aadharTargetPath = 'uploads/aadhar/' . $aadharFileName;
    
    if (move_uploaded_file($_FILES['aadharfile']['tmp_name'], $aadharTargetPath)) {
        $aadharurl = "https://yourdomain.com/uploads/aadhar/" . $aadharFileName;
    }
} else {
    $aadharurl = $existing['aadharurl'] ?? '';
}

// Upload Photo file if provided
if (isset($_FILES['photofile']) && $_FILES['photofile']['error'] == 0) {
    $photoFileName = uniqid() . '_' . basename($_FILES['photofile']['name']);
    $photoTargetPath = 'uploads/photo/' . $photoFileName;
    
    if (move_uploaded_file($_FILES['photofile']['tmp_name'], $photoTargetPath)) {
        $photourl = "https://yourdomain.com/uploads/photo/" . $photoFileName;
    }
} else {
    $photourl = $existing['photourl'] ?? '';
}

// Update customer
$sql = "UPDATE customermaster SET 
    customername = ?, 
    gst_no = ?, 
    address = ?, 
    area = ?, 
    areaid = ?, 
    mobile1 = ?, 
    mobile2 = ?, 
    refer = ?, 
    refercontact = ?, 
    spousename = ?, 
    spousecontact = ?, 
    aadharurl = ?, 
    photourl = ?, 
    addedby = ? 
    WHERE id = ? AND companyid = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssssssssssssssss", 
    $customername, $gst_no, $address, $area, $areaid, 
    $mobile1, $mobile2, $refer, $refercontact, $spousename, 
    $spousecontact, $aadharurl, $photourl, $addedby,
    $customerid, $companyid);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(["status" => "success", "message" => "Customer updated successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "No changes made or customer not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Failed to update customer"]);
}

$stmt->close();
$conn->close();
?>