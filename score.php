<?php

$key = $argv[1];
$score = $argv[2];
$iv = $argv[3];

$scoreData = mcrypt_decrypt(MCRYPT_RIJNDAEL_256, $key, base64_decode($score), MCRYPT_MODE_CBC, base64_decode($iv));

echo($scoreData);

