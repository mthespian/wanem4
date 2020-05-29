#!/bin/bash

#ps ax | grep httpd | grep -vq grep

until [ $(pgrep apache2 | wc -l) -gt 0 ]; do
     echo "Httpd Waiting.. "
    sleep 1
   done
/usr/bin/arora

