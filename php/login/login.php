<?php
include 'cors.php';
include 'conn.php';
header("Access-Control-Allow-Origin: *");
if ($conn->connect_error) {
 die("Connection failed: " . $conn->connect_error);
} 

 $json = file_get_contents('php://input');
 
 $obj = json_decode($json,true);
 
 $platform = $obj['platform'];
 $username = $obj['username'];
 $password = $obj['password'];
 $email = $obj['email'];
 $unique_id = $obj['unique_id'];
 $platform = $obj['platform'];


if($platform == 1){
$sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} else {
 echo "login not success";
}
}
else{
$sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
left join companymaster c on c.id = m.companyid where m.staffname = '$username' 
and  m.password = '$password' and c.email_id ='$email' and m.unique_id ='$unique_id'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} 

else {
	
$sql2 = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result2 = $conn->query($sql2);
 
if ($result2->num_rows >0) {
	
 $res=mysqli_query($conn,"select m.user_type,m.unique_id,m.id,m.companyid from staffmaster m 
 left join companymaster c on c.id = m.companyid WHERE m.staffname = '$username' 
 and  m.password = '$password' and c.email_id ='$email' limit 1");
 
 while($row=mysqli_fetch_array($res)) 	
 {
    $user_type =$row['user_type']; 
    $unique_identity =$row['unique_id']; 
    $user_id =$row['id']; 
    $company_id =$row['companyid']; 
 }

if($user_type != 'ADMIN'){	
 if (($unique_identity == '') || ($unique_identity == 'NULL')) {
	 
	 
$sqll = "SELECT * FROM staffmaster WHERE unique_id = '$unique_id'";
 
$resultl = $conn->query($sqll);
 
if ($resultl->num_rows >0) {
	
 echo "This is not your device.Please login in your device.";
  
}

else{	

 $Sql_Query = "UPDATE staffmaster SET unique_id = '$unique_id' WHERE id= '$user_id' and companyid = '$company_id'";
  
 if(mysqli_query($conn,$Sql_Query)){
	 
 $res=mysqli_query($conn,"select m.unique_id from staffmaster m 
 left join companymaster c on c.id = m.companyid 
 WHERE m.staffname = '$username' 
 and  m.password = '$password' and c.email_id ='$email' limit 1");
 
 while($row=mysqli_fetch_array($res)) 	
 {
    $unique_identity =$row['unique_id']; 
 }	 
	 
	
 $sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
 left join companymaster c on c.id = m.companyid 
 where m.staffname = '$username' and  m.password = '$password' 
 and c.email_id ='$email' and m.unique_id ='$unique_identity'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

 } 
else{
	
 echo "This is not your device.Please login in your device.";

 }	
 }
 else{
	
 echo "This is not your device.Please login in your device.";
	
 }
 }
 }
 else{
	
 echo "This is not your device.Please login in your device.";
	
}}

 else {
	 
	 $sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} else {
 echo "login not success";
}
	 
	 
 // echo "fsdffdsf";
}

 } 
 else {
 echo "login not success";
}
}
}

$conn->close();

?>
