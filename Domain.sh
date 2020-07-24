#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`


if [ "$1" != "" ]; then
    echo "Take a coffee now I am doing it for you ^_^"
    mkdir ./$1
    cd $1
    touch $1.txt
    
    #amass
    echo "${green}Running Amass${reset}"
    amass enum -o $1.txt -passive -d $1 > /dev/null
    
    #assetfinder
    echo "${green}Running Assetfinder${reset}"
    source ~/.profile
    assetfinder -subs-only $1 >> $1.txt
    
    cat $1.txt | uniq -u > uniq.txt

    #http probe
    echo "${green}running httprobe${reset}"
    source ~/.profile
    cat $1.txt |sort -u | while read line; do   httprobe -c 200 $line >> working_urls.txt;   done
    #cat $1.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do     probeurl=$(cat working_urls.txt | sort -u | grep -m 1 $line);     echo #"$probeurl" >> urllist.txt;     done
    
    #Aquatone
    mkdir aqua_out
    echo "${green}Starting aquatone scan...${reset}"
    cat working_urls.txt |aquatone -chrome-path /usr/bin/chromium -out ./aqua_out -threads 10 -silent -screenshot-timeout 100000; 
    
    #Url scan...
    echo "${green}Running Urlscan.io API ${reset}"
    cat $1.txt | sort -u | while read line; do    gron "https://urlscan.io/api/v1/search/?q=$line";  done| grep 'url' | gron --ungron >>urlscan.txt
    
    #wayback url
    waybackurls $1 > $1_wayback.txt

    #Javascript Gathering and link finder
    echo "${green}Collecting JS data ${reset}"
    bash /root/Desktop/tools/scripts/js.sh
    
    #For Detecting Secrets in JS files
    echo "${green}Running Secret Finder on Working URLs ${reset}"
    cat working_urls.txt | while read line; do python3 ~/Desktop/tools/SecretFinder/SecretFinder.py -i $line -e -o cli; done
    echo "${green}Running Secret Finder on Wayback Data ${reset}"
    cat $1_wayback.txt | while read line; do python3 ~/Desktop/tools/SecretFinder/SecretFinder.py -i $line -e -o cli; done
    
    #Checking For SSRF in headers
    cat working_urls.txt |python3 ssrf.py https://webhook.site/273ff719-40f1-44ed-a335-a59a72b7372a

    
else
    echo "Please enter domain"
fi
