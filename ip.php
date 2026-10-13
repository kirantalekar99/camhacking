<?php
// Capture visitor IP address (check proxy headers first)
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    // May contain multiple IPs (client, proxy1, proxy2...) — take the first
    $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
    $ipaddress = trim($parts[0]);
} else {
    $ipaddress = $_SERVER['REMOTE_ADDR'];
}

// Sanitize: strip any newlines to prevent log injection
$ipaddress = preg_replace('/[\r\n]/', '', $ipaddress);

// Capture User-Agent and sanitize
$browser = isset($_SERVER['HTTP_USER_AGENT'])
    ? preg_replace('/[\r\n]/', '', $_SERVER['HTTP_USER_AGENT'])
    : 'Unknown';

$file = 'ip.txt';
$fp   = fopen($file, 'a');

if ($fp !== false) {
    fwrite($fp, "IP: "         . $ipaddress . "\r\n");
    fwrite($fp, "User-Agent: " . $browser   . "\r\n");
    fwrite($fp, "---\r\n");   // separator so multiple visits stay readable
    fclose($fp);
}
?>
