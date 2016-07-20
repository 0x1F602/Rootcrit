# Rootcrit

## This is not ready for production code, at all. Use at your own risk.

Rootcrit is a Linux remote administration tool intended to run as root.

If you're not into running webservers as root (you really shouldn't due to obvious security issues), then you can expose certain functionalities using setuid more or less. The most important one is shutdown. Rootcrit is intended to allow the user to monitor a their 'top', 'who' and 'uptime' as well as shutdown the machine via their phone or any other web browser.

## Features

Remote shutdown the computer

View the currently logged in users and `top` output.

Start and stop `motion` security system

## Get started

You should be able to use the setup.sh file to get started. You'll need to install plenv and carton for Perl support. You'll also need a cassandra instance in the cloud and a pair of GPG keys. You'll want to edit the config file (it's just a perl hash we load as is, so be careful).

## Release notes

### 2016-06-06

Fixed the bug with OpenPGP.js getting overwhelmed when attempting to open multiple files at once

### 2016-03-19

Made a little bit of OpenPGP.js and Gallery support. I have everything loaded and ready for the actual meat of the work now. We are also able to download incidents from Cassandra and display them in a list. Now working on a place to put the PGP private key for in-browser decryption.

### 2016-03-07

Slowly working my way toward gallery support. You can now disable the system info updates as well.

Next step: Add openpgp.js
