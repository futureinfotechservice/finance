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

// Log everything to a file for debugging
$logFile = __DIR__ . '/debug.log';
file_put_contents($logFile, "=== " . date('Y-m-d H:i:s') . " ===\n", FILE_APPEND);

// Initialize response array
$response = ["status" => "error", "message" => "Unknown error"];

try {
    // Log all received data
    file_put_contents($logFile, "POST data received:\n", FILE_APPEND);
    foreach ($_POST as $key => $value) {
        if ($key === 'aadhar_base64' || $key === 'photo_base64') {
            file_put_contents($logFile, "  $key: " . substr($value, 0, 100) . "...\n", FILE_APPEND);
        } else {
            file_put_contents($logFile, "  $key: $value\n", FILE_APPEND);
        }
    }
    
    file_put_contents($logFile, "FILES data:\n", FILE_APPEND);
    foreach ($_FILES as $key => $file) {
        file_put_contents($logFile, "  $key: " . json_encode($file) . "\n", FILE_APPEND);
    }

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
    $platform = isset($_POST['platform']) ? $_POST['platform'] : 'mobile';

    file_put_contents($logFile, "Platform: $platform\n", FILE_APPEND);

    // Base URL for file URLs
    $baseUrl = "https://financeapi.futureinfotechservices.in";

    // Create uploads directory if it doesn't exist
    $uploadDir = __DIR__ . '/uploads/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
    if (!file_exists($uploadDir . 'aadhar/')) {
        mkdir($uploadDir . 'aadhar/', 0777, true);
    }
    if (!file_exists($uploadDir . 'photo/')) {
        mkdir($uploadDir . 'photo/', 0777, true);
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

    // Handle Aadhar file (both web and mobile)
    if ($platform == 'web' && isset($_POST['aadhar_base64']) && !empty($_POST['aadhar_base64'])) {
        // Web: Base64 file
        $base64Data = $_POST['aadhar_base64'];
        $filename = isset($_POST['aadhar_filename']) ? $_POST['aadhar_filename'] : uniqid() . '_aadhar.png';
        
        file_put_contents($logFile, "Processing Aadhar base64 data\n", FILE_APPEND);
        
        // Extract base64 data
        if (preg_match('/^data:(.*?);base64,/', $base64Data, $type)) {
            file_put_contents($logFile, "Detected data URI with type: {$type[1]}\n", FILE_APPEND);
            
            $data = substr($base64Data, strpos($base64Data, ',') + 1);
            $type = strtolower($type[1]);
            
            // Validate file type
            $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf'];
            if (!in_array($type, $allowedTypes)) {
                throw new Exception('Invalid file type for Aadhar. Allowed: jpg, png, gif, pdf. Got: ' . $type);
            }
            
            $data = base64_decode($data);
            if ($data === false) {
                throw new Exception('Base64 decode failed for Aadhar');
            }
            
            $filePath = $uploadDir . 'aadhar/' . $filename;
            if (file_put_contents($filePath, $data)) {
                $aadharurl = $baseUrl . "/uploads/aadhar/" . $filename;
                file_put_contents($logFile, "Aadhar saved: $filePath\n", FILE_APPEND);
                file_put_contents($logFile, "Aadhar URL: $aadharurl\n", FILE_APPEND);
            } else {
                throw new Exception('Failed to save Aadhar file to: ' . $filePath);
            }
        } else {
            file_put_contents($logFile, "ERROR: Not a valid data URI\n", FILE_APPEND);
            throw new Exception('Invalid base64 data format for Aadhar');
        }
    } elseif (isset($_FILES['aadharfile']) && $_FILES['aadharfile']['error'] == 0) {
        // Mobile: File upload
        $aadharFileName = uniqid() . '_' . basename($_FILES['aadharfile']['name']);
        $aadharTargetPath = $uploadDir . 'aadhar/' . $aadharFileName;
        
        if (move_uploaded_file($_FILES['aadharfile']['tmp_name'], $aadharTargetPath)) {
            $aadharurl = $baseUrl . "/uploads/aadhar/" . $aadharFileName;
        }
    }

    // Handle Photo file (both web and mobile)
    if ($platform == 'web' && isset($_POST['photo_base64']) && !empty($_POST['photo_base64'])) {
        // Web: Base64 file
        $base64Data = $_POST['photo_base64'];
        $filename = isset($_POST['photo_filename']) ? $_POST['photo_filename'] : uniqid() . '_photo.png';
        
        file_put_contents($logFile, "Processing Photo base64 data\n", FILE_APPEND);
        
        // Extract base64 data
        if (preg_match('/^data:(.*?);base64,/', $base64Data, $type)) {
            file_put_contents($logFile, "Detected data URI with type: {$type[1]}\n", FILE_APPEND);
            
            $data = substr($base64Data, strpos($base64Data, ',') + 1);
            $type = strtolower($type[1]);
            
            // Validate file type
            $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            if (!in_array($type, $allowedTypes)) {
                throw new Exception('Invalid file type for Photo. Allowed: jpg, png, gif. Got: ' . $type);
            }
            
            $data = base64_decode($data);
            if ($data === false) {
                throw new Exception('Base64 decode failed for Photo');
            }
            
            $filePath = $uploadDir . 'photo/' . $filename;
            if (file_put_contents($filePath, $data)) {
                $photourl = $baseUrl . "/uploads/photo/" . $filename;
                file_put_contents($logFile, "Photo saved: $filePath\n", FILE_APPEND);
                file_put_contents($logFile, "Photo URL: $photourl\n", FILE_APPEND);
            } else {
                throw new Exception('Failed to save Photo file to: ' . $filePath);
            }
        } else {
            file_put_contents($logFile, "ERROR: Not a valid data URI\n", FILE_APPEND);
            throw new Exception('Invalid base64 data format for Photo');
        }
    } elseif (isset($_FILES['photofile']) && $_FILES['photofile']['error'] == 0) {
        // Mobile: File upload
        $photoFileName = uniqid() . '_' . basename($_FILES['photofile']['name']);
        $photoTargetPath = $uploadDir . 'photo/' . $photoFileName;
        
        if (move_uploaded_file($_FILES['photofile']['tmp_name'], $photoTargetPath)) {
            $photourl = $baseUrl . "/uploads/photo/" . $photoFileName;
        }
    }

    file_put_contents($logFile, "Final URLs - Aadhar: $aadharurl, Photo: $photourl\n", FILE_APPEND);

    // Insert customer
    $sql = "INSERT INTO customermaster 
        (companyid, customername, gst_no, address, area, areaid, mobile1, mobile2, 
         refer, refercontact, spousename, spousecontact, aadharurl, photourl, 
         addedby, activestatus) 
        VALUES ('$companyid', '$customername', '$gst_no', '$address', '$area', '$areaid', 
                '$mobile1', '$mobile2', '$refer', '$refercontact', '$spousename', 
                '$spousecontact', '$aadharurl', '$photourl', '$addedby', '$activestatus')";

    file_put_contents($logFile, "SQL: $sql\n", FILE_APPEND);

    if (mysqli_query($conn, $sql)) {
        $response["status"] = "success";
        $response["message"] = "Customer created successfully";
        $response["customer_id"] = mysqli_insert_id($conn);
        $response["aadhar_url"] = $aadharurl;
        $response["photo_url"] = $photourl;
        
        file_put_contents($logFile, "SUCCESS: Customer inserted\n", FILE_APPEND);
    } else {
        $response["message"] = "Failed to create customer: " . mysqli_error($conn);
        file_put_contents($logFile, "ERROR: " . mysqli_error($conn) . "\n", FILE_APPEND);
    }

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
    file_put_contents($logFile, "EXCEPTION: " . $e->getMessage() . "\n", FILE_APPEND);
}

// Always output valid JSON
file_put_contents($logFile, "Response: " . json_encode($response) . "\n\n", FILE_APPEND);
echo json_encode($response);

// Close connection
mysqli_close($conn);
?>