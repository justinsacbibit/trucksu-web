<?php

//$key_file = fopen("key", "r") or die("Unable to open key file");
//$key = fread($key_file, filesize("key"));
//fclose($key_file);
// $key = "h89f2-890h2h89b34g-h80g134n90133";
$key = $argv[1];
$score = $argv[2];
$iv = $argv[3];

// $score_file = fopen($score_file_path, "r") or die("Unable to open score file");
// $score = fread($score_file, filesize($score_file_path));
// fclose($score_file);

// $iv_file = fopen($iv_file_path, "r") or die("Unable to open iv file");
// $iv = fread($iv_file, filesize($iv_file_path));
// fclose($iv_file);

// echo $key;
// echo $score;
// echo $iv;

$scoreData = mcrypt_decrypt(MCRYPT_RIJNDAEL_256, $key, base64_decode($score), MCRYPT_MODE_CBC, base64_decode($iv));

echo($scoreData);

// $decrypted_score_file = fopen("decrypted_score", "w") or die("Unable to open decrypted score file");
// fwrite($decrypted_score_file, $scoreData);
// fclose($decrypted_score_file);

//$scoreDataArray = explode(":", $scoreData);

//$username = rtrim($scoreDataArray[1], " ");

//echo($username);
