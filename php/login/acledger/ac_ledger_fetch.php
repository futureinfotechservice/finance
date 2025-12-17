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

    $sql = "SELECT * FROM acledger WHERE companyid = '$companyid' ORDER BY ledgername ASC";
    $result = mysqli_query($conn, $sql);

    $ledgers = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $ledgers[] = $row;
    }

    echo json_encode($ledgers);

} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}

if ($conn) {
    mysqli_close($conn);
}
?>