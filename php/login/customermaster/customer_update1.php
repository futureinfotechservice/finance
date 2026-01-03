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
    if (!isset($_POST['customerid']) || !isset($_POST['companyid'])) {
        $response["message"] = "Required fields missing";
        echo json_encode($response);
        exit();
    }

    $customerid = mysqli_real_escape_string($conn, $_POST['customerid']);
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
    $customername = isset($_POST['customername']) ? mysqli_real_escape_string($conn, $_POST['customername']) : '';
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
    $platform = isset($_POST['platform']) ? $_POST['platform'] : 'mobile';

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

    // Get existing file URLs first
    $sqlCheck = "SELECT aadharurl, photourl FROM customermaster WHERE id = ? AND companyid = ?";
    $stmtCheck = $conn->prepare($sqlCheck);
    $stmtCheck->bind_param("ss", $customerid, $companyid);
    $stmtCheck->execute();
    $resultCheck = $stmtCheck->get_result();
    $existing = $resultCheck->fetch_assoc();
    $stmtCheck->close();

    // Initialize file URLs with existing values
    $aadharurl = $existing['aadharurl'] ?? '';
    $photourl = $existing['photourl'] ?? '';

    // Handle Aadhar file (both web and mobile)
    if ($platform == 'web' && isset($_POST['aadhar_base64']) && !empty($_POST['aadhar_base64'])) {
        // Web: Base64 file
        $base64Data = $_POST['aadhar_base64'];
        $filename = $_POST['aadhar_filename'] ?? uniqid() . '_aadhar.png';
        
        // Extract base64 data
        if (preg_match('/^data:(.*?);base64,/', $base64Data, $type)) {
            $data = substr($base64Data, strpos($base64Data, ',') + 1);
            $type = strtolower($type[1]);
            
            // Validate file type
            $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf'];
            if (!in_array($type, $allowedTypes)) {
                throw new Exception('Invalid file type for Aadhar. Allowed: jpg, png, gif, pdf');
            }
            
            $data = base64_decode($data);
            if ($data === false) {
                throw new Exception('Base64 decode failed for Aadhar');
            }
            
            $filePath = $uploadDir . 'aadhar/' . $filename;
            if (file_put_contents($filePath, $data)) {
                $aadharurl = $baseUrl . "/uploads/aadhar/" . $filename;
                
                // Delete old file if it exists
                if (!empty($existing['aadharurl'])) {
                    $oldFilename = basename($existing['aadharurl']);
                    $oldFilePath = $uploadDir . 'aadhar/' . $oldFilename;
                    if (file_exists($oldFilePath)) {
                        unlink($oldFilePath);
                    }
                }
            } else {
                throw new Exception('Failed to save Aadhar file');
            }
        } else {
            throw new Exception('Invalid base64 data format for Aadhar');
        }
    } elseif (isset($_FILES['aadharfile']) && $_FILES['aadharfile']['error'] == 0) {
        // Mobile: File upload
        $aadharFileName = uniqid() . '_' . basename($_FILES['aadharfile']['name']);
        $aadharTargetPath = $uploadDir . 'aadhar/' . $aadharFileName;
        
        // Validate file type
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'pdf'];
        $fileExtension = strtolower(pathinfo($_FILES['aadharfile']['name'], PATHINFO_EXTENSION));
        
        if (!in_array($fileExtension, $allowedExtensions)) {
            throw new Exception('Invalid file type for Aadhar. Allowed: jpg, png, gif, pdf');
        }
        
        if (move_uploaded_file($_FILES['aadharfile']['tmp_name'], $aadharTargetPath)) {
            $aadharurl = $baseUrl . "/uploads/aadhar/" . $aadharFileName;
            
            // Delete old file if it exists
            if (!empty($existing['aadharurl'])) {
                $oldFilename = basename($existing['aadharurl']);
                $oldFilePath = $uploadDir . 'aadhar/' . $oldFilename;
                if (file_exists($oldFilePath)) {
                    unlink($oldFilePath);
                }
            }
        } else {
            throw new Exception('Failed to upload Aadhar file');
        }
    }

    // Handle Photo file (both web and mobile)
    if ($platform == 'web' && isset($_POST['photo_base64']) && !empty($_POST['photo_base64'])) {
        // Web: Base64 file
        $base64Data = $_POST['photo_base64'];
        $filename = $_POST['photo_filename'] ?? uniqid() . '_photo.png';
        
        // Extract base64 data
        if (preg_match('/^data:(.*?);base64,/', $base64Data, $type)) {
            $data = substr($base64Data, strpos($base64Data, ',') + 1);
            $type = strtolower($type[1]);
            
            // Validate file type
            $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            if (!in_array($type, $allowedTypes)) {
                throw new Exception('Invalid file type for Photo. Allowed: jpg, png, gif');
            }
            
            $data = base64_decode($data);
            if ($data === false) {
                throw new Exception('Base64 decode failed for Photo');
            }
            
            $filePath = $uploadDir . 'photo/' . $filename;
            if (file_put_contents($filePath, $data)) {
                $photourl = $baseUrl . "/uploads/photo/" . $filename;
                
                // Delete old file if it exists
                if (!empty($existing['photourl'])) {
                    $oldFilename = basename($existing['photourl']);
                    $oldFilePath = $uploadDir . 'photo/' . $oldFilename;
                    if (file_exists($oldFilePath)) {
                        unlink($oldFilePath);
                    }
                }
            } else {
                throw new Exception('Failed to save Photo file');
            }
        } else {
            throw new Exception('Invalid base64 data format for Photo');
        }
    } elseif (isset($_FILES['photofile']) && $_FILES['photofile']['error'] == 0) {
        // Mobile: File upload
        $photoFileName = uniqid() . '_' . basename($_FILES['photofile']['name']);
        $photoTargetPath = $uploadDir . 'photo/' . $photoFileName;
        
        // Validate file type
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        $fileExtension = strtolower(pathinfo($_FILES['photofile']['name'], PATHINFO_EXTENSION));
        
        if (!in_array($fileExtension, $allowedExtensions)) {
            throw new Exception('Invalid file type for Photo. Allowed: jpg, png, gif');
        }
        
        if (move_uploaded_file($_FILES['photofile']['tmp_name'], $photoTargetPath)) {
            $photourl = $baseUrl . "/uploads/photo/" . $photoFileName;
            
            // Delete old file if it exists
            if (!empty($existing['photourl'])) {
                $oldFilename = basename($existing['photourl']);
                $oldFilePath = $uploadDir . 'photo/' . $oldFilename;
                if (file_exists($oldFilePath)) {
                    unlink($oldFilePath);
                }
            }
        } else {
            throw new Exception('Failed to upload Photo file');
        }
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
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("ssssssssssssssss", 
        $customername, $gst_no, $address, $area, $areaid, 
        $mobile1, $mobile2, $refer, $refercontact, $spousename, 
        $spousecontact, $aadharurl, $photourl, $addedby,
        $customerid, $companyid);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            $response["status"] = "success";
            $response["message"] = "Customer updated successfully";
        } else {
            $response["status"] = "success";
            $response["message"] = "No changes made or customer not found";
        }
    } else {
        $response["message"] = "Failed to update customer: " . $stmt->error;
    }
    
    $stmt->close();

} catch (Exception $e) {
    $response["message"] = "Exception: " . $e->getMessage();
}

// Always output valid JSON
echo json_encode($response);

// Close connection
if (isset($conn) && $conn) {
    $conn->close();
}
exit();
?>