#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

#curl installation
if ! command -v curl &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} curl is not installed. Please install it first."
    exit 1
fi

#params
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}[USAGE]${NC} $0 <base_url> [payloads_file]"
    echo -e "Example: $0 'http://example.com/page?param=' payloads.txt"
    exit 1
fi

BASE_URL=$1
PAYLOADS_FILE=${2:-payloads.txt}

#is there a file with payloads
if [ ! -f "$PAYLOADS_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Payloads file '$PAYLOADS_FILE' not found!"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Testing URL: $BASE_URL"
echo -e "${GREEN}[INFO]${NC} Using payloads from: $PAYLOADS_FILE"
echo -e "${YELLOW}[STATUS]${NC} Starting tests...\n"

#stats
TOTAL=0
VULNERABLE=0
RESULTS_FILE="scan_results_$(date +%Y%m%d_%H%M%S).txt"

#clear old results
> "$RESULTS_FILE"
> vulnerable_urls.txt

#pathTraversal func
check_path_traversal() {
    local url=$1
    local response=$2
    if [[ "$response" =~ /etc/passwd ]] || 
    [[ "$response" =~ root:[x*]:0:0: ]] || 
    [[ "$response" =~ "boot.ini" ]] || 
    [[ "$response" =~ "Windows" ]] || 
    [[ "$response" =~ "<?xml" ]] || 
    [ "$(echo "$response" | wc -l)" -gt 50 ]; then
        return 0
    fi
    return 1
}

#testing 1 payload
test_payload() {
    local payload=$1
    local full_url="${BASE_URL}${payload}"
    
    echo -n "[$TOTAL] Testing: $payload ... " | tee -a "$RESULTS_FILE"
    
    #sending
    response=$(curl -k -s -w "\nHTTP_CODE:%{http_code}" --connect-timeout 5 "$full_url")
    http_code=$(echo "$response" | grep 'HTTP_CODE:' | cut -d':' -f2)
    response_content=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    #saving
    echo -e "[$TOTAL] URL: $full_url" >> "$RESULTS_FILE"
    echo "Payload: $payload" >> "$RESULTS_FILE"
    echo "HTTP Code: $http_code" >> "$RESULTS_FILE"
    
    #vuln check
    vuln_found=0
    if [ "$http_code" -eq 200 ]; then
        if check_path_traversal "$full_url" "$response_content"; then
            echo -e "${GREEN}[PATH TRAVERSAL FOUND]${NC} Code: $http_code" | tee -a "$RESULTS_FILE"
            echo "$full_url" >> vulnerable_urls.txt
            vuln_found=1
        elif [[ "$response_content" =~ "root:" ]] || [[ "$response_content" =~ "boot.ini" ]]; then
            echo -e "${GREEN}[LFI FOUND]${NC} Code: $http_code" | tee -a "$RESULTS_FILE"
            echo "$full_url" >> vulnerable_urls.txt
            vuln_found=1
        else
            echo -e "[OK] Code: $http_code" | tee -a "$RESULTS_FILE"
        fi
    elif [ "$http_code" -eq 500 ]; then
        echo -e "${YELLOW}[SERVER ERROR]${NC} Code: $http_code" | tee -a "$RESULTS_FILE"
    elif [ "$http_code" -eq 403 ]; then
        echo -e "${BLUE}[FORBIDDEN]${NC} Code: $http_code" | tee -a "$RESULTS_FILE"
    else
        echo -e "[CODE] $http_code" | tee -a "$RESULTS_FILE"
    fi
    
    #outputing first 100 chars
    echo "Response snippet: ${response_content:0:100}..." >> "$RESULTS_FILE"
    echo "----------------------------------------" >> "$RESULTS_FILE"
    
    if [ $vuln_found -eq 1 ]; then
        ((VULNERABLE++))
    fi
    ((TOTAL++))
}

#read & test payloads
while IFS= read -r payload || [ -n "$payload" ]; do
    
    #skip comments and zero strings
    if [[ -z "$payload" || "$payload" =~ ^# ]]; then
        continue
    fi
    
    #URL-encoding
    encoded_payload=$(printf "%s" "$payload" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
    
    #test enco and orig payloads
    test_payload "$payload"
    test_payload "$encoded_payload"
    
    sleep 0.05
done < "$PAYLOADS_FILE"

#print stats
echo -e "\n${YELLOW}[RESULTS]${NC}"
echo -e "Total payloads tested: $TOTAL" | tee -a "$RESULTS_FILE"
echo -e "${GREEN}Possible vulnerabilities found: $VULNERABLE${NC}" | tee -a "$RESULTS_FILE"

if [ $VULNERABLE -gt 0 ]; then
    echo -e "${YELLOW}Vulnerable URLs saved to: vulnerable_urls.txt${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${YELLOW}Full scan results saved to: $RESULTS_FILE${NC}" | tee -a "$RESULTS_FILE"
fi

#print all results
echo -e "\n${BLUE}[TESTED URLS]${NC}"
cat "$RESULTS_FILE" | grep -E "URL:|HTTP Code:|\[PATH TRAVERSAL FOUND\]|\[LFI FOUND\]"

exit 0