<a href="/">Back</a><br>
<?php
$mysql_conf = array(
  'host'    => '127.0.0.1:3306', 
  'db'      => 'mysql', 
  'db_user' => 'root', 
  'db_pwd'  => 'root', 
);

$mysqli = @new mysqli($mysql_conf['host'], $mysql_conf['db_user'], $mysql_conf['db_pwd']);
if ($mysqli->connect_errno) {
  die("could not connect to the database:\n" . $mysqli->connect_error);
}

$mysqli->query("set names 'utf8';");
$select_db = $mysqli->select_db($mysql_conf['db']);
if (!$select_db) {
  die("could not connect to the db:\n" .  $mysqli->error);
}

$sql = "select count(*) from user;";
$res = $mysqli->query($sql);
if (!$res) {
  die("sql error:\n" . $mysqli->error);
}

while ($row = $res->fetch_assoc()) {
  var_dump($row);
}

$res->free();
$mysqli->close();
?>
