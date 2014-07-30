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
      }

	  body {
		font: 0.875em/1.3 "Segoe UI","Lucida Grande",Verdana,Arial,Helvetica,sans-serif;
		color: #000;
		background: none repeat scroll 0% 0% #f8f8f8;
	  }
	  
      h1 {
		font-weight: bold;
		margin-top: 30px;
		color: #F90;
		margin-bottom: 5px;
		font-size: 2em;
		text-shadow: 0 3px 3px #d8d8d8;		
      }

      h2 {
		font-weight: bold;
		color: #3AD9FF;
		margin-top: 30px;
		margin-bottom: 0px;
		font-size: 1.2em;
		text-shadow: 0 2px 2px #d8d8d8;
      }
	  
		p {
			margin-top: 0px;
		}
		
		ul {
			margin-top: 5px;
		}
		
		li {
			margin-bottom: 3px;
		}		
    </style>
    <body>
		<?php
			# Put HTML content in the document
			echo $html;
		?>
    </body>
</html>
