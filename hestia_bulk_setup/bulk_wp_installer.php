<?php

// /root/scripts/bulk_wp_installer.php
// php /root/scripts/bulk_wp_installer.php
// [ i want to make bulk wordpress 200 sites on vps server using cpanel hestia on ubuntu operating system.
// and also i want import my wordpress site backup also automiatically. how i can achieve this goal perfectly/securiy/automatically.
// also if upload my wordpress site backup can it leaks the security implementation while when i am installing wordpress from cpanel
// wordpress installor i think this installing a perfect secure wordpress setup with secure wordpress db tables and attaching phpmyadmin
// by domain.com/phpmyadmin ]

// CONFIGURATION
$backupDir = '/root/backups/';
$logFile = '/root/scripts/logs.txt';
$siteList = [
    ['domain' => 'site1.com', 'username' => 'user1'],
    ['domain' => 'site2.com', 'username' => 'user2'],
    // Add more sites here...
];

// Helper functions
function run($cmd) {
    global $logFile;
    $output = shell_exec($cmd . ' 2>&1');
    file_put_contents($logFile, "$cmd\n$output\n\n", FILE_APPEND);
    return $output;
}

function randomPassword($length = 12) {
    return bin2hex(random_bytes($length / 2));
}

foreach ($siteList as $site) {
    $domain = $site['domain'];
    $username = $site['username'];
    $dbName = str_replace('.', '_', $domain) . '_db';
    $dbUser = str_replace('.', '_', $domain) . '_user';
    $dbPass = randomPassword();

    echo "Processing $domain...\n";

    // Step 1: Create Hestia user and domain
    run("v-add-user $username " . randomPassword() . " default");
    run("v-add-domain $username $domain");
    run("v-add-web-domain $username $domain");

    // Step 2: Create MySQL DB
    run("v-add-database $username mysql $dbName $dbUser $dbPass");

    // Step 3: Extract backup
    $backupZip = $backupDir . $domain . '.zip';
    $extractTo = "/home/$username/web/$domain/";
    run("unzip -o $backupZip -d $extractTo");

    // Step 4: Import DB
    $dbPath = $extractTo . "public_html/db.sql";
    run("mysql -u $dbUser -p'$dbPass' $dbName < $dbPath");

    // Step 5: Update wp-config.php
    $wpConfigPath = $extractTo . "public_html/wp-config.php";
    $wpConfig = file_get_contents($wpConfigPath);
    $wpConfig = str_replace("database_name_here", $dbName, $wpConfig);
    $wpConfig = str_replace("username_here", $dbUser, $wpConfig);
    $wpConfig = str_replace("password_here", $dbPass, $wpConfig);
    file_put_contents($wpConfigPath, $wpConfig);

    // Step 6: Fix permissions
    run("chown -R $username:$username /home/$username/web/$domain/public_html");

    // Step 7: Enable Let's Encrypt SSL
    run("v-add-letsencrypt-domain $username $domain");

    echo "✔ Done: $domain\n";
}

echo "✅ All sites processed.\n";
