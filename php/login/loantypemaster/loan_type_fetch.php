<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$response = [];

try {
    if ($conn->connect_error) {
        throw new Exception("Connection failed");
    }

    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');

    if (empty($companyid)) {
        throw new Exception("Company ID is required");
    }

    $sql = "SELECT * FROM loantypemaster WHERE companyid = '$companyid' ORDER BY id DESC";
    $result = mysqli_query($conn, $sql);

    $loanTypes = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $loanTypes[] = $row;
    }

    echo json_encode($loanTypes);

} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}

if ($conn) {
    mysqli_close($conn);
}
?>