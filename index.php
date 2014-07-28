<?php

# This file passes the content of the Readme.md file in the same directory
# through the Markdown filter. You can adapt this sample code in any way
# you like.

# Install PSR-0-compatible class autoloader
spl_autoload_register(function($class){
	require preg_replace('{\\\\|_(?!.*\\\\)}', DIRECTORY_SEPARATOR, ltrim($class, '\\')).'.php';
});

# Get Markdown class
use \Michelf\Markdown;

# Read file and pass content through the Markdown parser
$text = file_get_contents('Documentation.md');
$html = Markdown::defaultTransform($text);

?>
<!DOCTYPE html>
<html>
    <head>
        <title>ElTorqiro_AegisHUD User Documentation</title>
    </head>

    <style type="text/css">
      html {
        font-family: helvetica, sans-serif;
        font-size: 12px;
        background: #ffffff;
      }

      h1 {
	font-size: 16px; font-weight: bold; color: #0099ff;
        margin-top: 30px;
      }

      h2 {
        font-size: 14px; font-weight: bold; color: #006699;
        margin-top: 30px;
      }
    </style>
    <body>
		<?php
			# Put HTML content in the document
			echo $html;
		?>
    </body>
</html>
