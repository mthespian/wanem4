<?php
        include("config.inc.php")
?>

<html><head><title> WANem2 </title>
</head>
<body bgcolor="#FFE87C">
<?php
                $command=$wanchar_DIR."/tcs_wanem_main.sh";
                $output=shell_exec($command." 2>&1");  //system call
                print "<br>";
		print "<pre>$output</pre>";

?>
</body></html>
