#!/bin/bash
#### SubDomain Enumerator Script #######

echo "Please Enter Domain Name: ";
read domain;

if [ -d ~/$domain ]
then
        echo "Directory $domain already exists, Exiting";
else
        echo "Creating a directory $domain";
        mkdir ~/$domain;
        touch ~/$domain/all.txt;

fi

echo ""

############# AMASS ###############
check=`which amass`

if [ ! -z "$check" ];
then
        echo "[+] Amass Enumeration"
        amass enum -passive -norecursive -nolocaldb -noalts -d $domain | anew >>~/$domain/all.txt;
else
        echo "[-] cannot find amass or amass is not installed!";
fi

######## Subfinder #######################

check=`which subfinder`

if [ ! -z "$check" ]
then 
        echo "[+] Subfinder Enumeration";
        subfinder -d $domain --silent | anew >>~/$domain/all.txt;
else
        echo " Cannot locate subfinder install it or configure path manually in script";
fi


############# waybackurl #####################

echo "[+] Running WayBackUrl";

curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{ print $3}'| sort -u | uniq | anew >>~/$domain/all.txt

echo "[+] Fetching URLS from WaybackUrl";

curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" > ~/$domain/waybackurl_list.txt



############### BufferDNS #############


echo "[+] BufferDNS Enumeration";

curl -s "https://dns.bufferover.run/dns?q=.$domain" | grep ".$domain" | awk -F, '{print $2}' | sed 's/"/ /g' | anew >>~/$domain/all.txt;

echo "[+] Collecting IP's from BufferDNS";

curl -s "https://dns.bufferover.run/dns?q=.$domain" | grep ".$domain" > ~/$domain/additional_info.txt



############ CERT.SH ##################

echo "[+] Enumerating subdomain through cert.sh";

curl -s "https://crt.sh/?q=$domain&output=json" | jq -r ".[].name_value" | sed 's/*.//g'|sort -u|uniq | anew >>~/$domain/all.txt


######### Censys ###################

echo "[+] Getting IP's list using Censys";

curl -s -X 'GET' \
  'https://search.censys.io/api/v2/hosts/search?q=$domain&per_page=50&virtual_hosts=INCLUDE' \
  -H 'accept: application/json' \
  -H 'Authorization: Basic <token>' | jq '.result.hits[].ip'| sed 's/"//g' > ~/$domain/censys_ip_list.txt


############## Security Trails ################3

echo "[+] Security Trails Subdomain enumeration ";

curl -s "https://api.securitytrails.com/v1/domain/$domain/subdomains" -H 'apikey: <api-key>'| jq '.subdomains[]' | sed 's/"//g' > ~/$domain/test

for i in $(cat ~/$domain/test); do echo $i.$domain >> ~/$domain/all.txt; done

#rm ~/$domain/test


#################### removing duplicates ################

cat ~/$domain/all.txt | sort -u | uniq > ~/$domain/final_subdomain.txt

cat ~/$domain/final_subdomain.txt | sed 's/ //g' | uniq > ~/$domain/sub.txt

rm ~/$domain/all.txt ~/$domain/test 
rm ~/$domain/final_subdomain.txt

echo "";

echo "[+] Enumerating using httprobe"
cat ~/$domain/sub.txt | httprobe >> ~/$domain/live-subs.txt
echo "[+] Done !!!!!"