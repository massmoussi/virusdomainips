#!/bin/bash

# Function to fetch related domains and IPs for a given domain
fetch_related_info() {
  local domain=$1
  local api_key_index=$2
  local api_key

  if [ $api_key_index -eq 1 ]; then
    api_key="key-1"
  elif [ $api_key_index -eq 2 ]; then
    api_key="key-2"
  else
    api_key="key-3"
  fi

  local URL="https://www.virustotal.com/vtapi/v2/domain/report?apikey=$api_key&domain=$domain"

  echo -e "\nFetching data for domain: \033[1;34m$domain\033[0m (using API key $api_key_index)"
  response=$(curl -s "$URL")
  if [[ $? -ne 0 ]]; then
    echo -e "\033[1;31mError fetching data for domain: $domain\033[0m"
    return
  fi

  # Extract subdomains (or related domains)
  related_domains=$(echo "$response" | jq -r '.subdomains[]?' 2>/dev/null)

  # Extract resolved IP addresses
  related_ips=$(echo "$response" | jq -r '.resolutions[]?.ip_address' 2>/dev/null)

  if [[ -z "$related_domains" && -z "$related_ips" ]]; then
    echo -e "\033[1;33mNo related domains or IPs found for domain: $domain\033[0m"
  else
    echo -e "\033[1;32mRelated domains for $domain:\033[0m"
    echo "$related_domains"

    echo -e "\033[1;35mRelated IPs for $domain:\033[0m"
    echo "$related_ips"
  fi
}

# Countdown between requests
countdown() {
  local seconds=$1
  while [ $seconds -gt 0 ]; do
    echo -ne "\033[1;36mWaiting for $seconds seconds...\033[0m\r"
    sleep 1
    : $((seconds--))
  done
  echo -ne "\033[0K"
}

# Argument check
if [ -z "$1" ]; then
  echo -e "\033[1;31mUsage: $0 <domain or file_with_domains>\033[0m"
  exit 1
fi

# API key rotation
api_key_index=1
request_count=0

# If input is a file
if [ -f "$1" ]; then
  while IFS= read -r domain; do
    domain=$(echo "$domain" | sed 's|https\?://||' | tr -d '[:space:]')
    if [[ -n "$domain" ]]; then
      fetch_related_info "$domain" $api_key_index
      countdown 20

      request_count=$((request_count + 1))
      if [ $request_count -ge 5 ]; then
        request_count=0
        if [ $api_key_index -eq 1 ]; then
          api_key_index=2
        elif [ $api_key_index -eq 2 ]; then
          api_key_index=3
        else
          api_key_index=1
        fi
      fi
    fi
  done < "$1"
else
  domain=$(echo "$1" | sed 's|https\?://||' | tr -d '[:space:]')
  fetch_related_info "$domain" $api_key_index
fi

echo -e "\033[1;32mAll done!\033[0m"
