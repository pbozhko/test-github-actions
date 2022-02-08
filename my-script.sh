#!/bin/bash

confluence_page_id="262277"
casbincsv_config_path="./test-service/src/main/resources/rbac.casbincsv"

index="1"
data_rows=""

while read -r line; do
  if [[ ${#line} -gt 0 ]] && ! [[ "$line" =~ ^# ]]; then
    IFS=', ' read -r -a permit_line <<<"$line"
    row="<tr><td>$index</td><td>${permit_line[1]}</td><td>${permit_line[3]}</td><td>${permit_line[4]}</td></tr>"
    data_rows+=$row
    index=$((index + 1))
  fi
done <"$casbincsv_config_path"

response=$(curl -s -X GET \
  -H "Authorization: Basic cC5ib3poa285MkBtYWlsLnJ1OlR6REJ3eWxodXVCUHZXTUJwRVE4NTA4Nw==" \
  "https://pbozhko.atlassian.net/wiki/rest/api/content/$confluence_page_id?expand=version,space")

version=$(jq -r '.version.number' <<<"$response")
space=$(jq -r '.space.key' <<<"$response")
title=$(jq -r '.title' <<<"$response")

new_version=$((version + 1))

echo "Space: $space"
echo "Page: $title"
echo "Current version: $version"
echo "New version: $new_version"

header_row="<tr><th>#<b></b></th><th><b>Role</b></th><th><b>Scope</b></th><th><b>Permit</b></th></tr>"
table_content="<table><thead>$header_row</thead><tbody>$data_rows</tbody></table>"

curl -X PUT \
  -H "Authorization: Basic cC5ib3poa285MkBtYWlsLnJ1OlR6REJ3eWxodXVCUHZXTUJwRVE4NTA4Nw==" \
  -H "Content-Type: application/json" \
  -d "{
            \"id\":\"$confluence_page_id\",
            \"type\":\"page\",
            \"title\":\"$title\",
            \"version\":{\"number\":\"$new_version\"},
            \"space\":{\"key\":\"$space\"},
            \"body\":{
                \"storage\":{
                    \"value\":\"$table_content\",
                    \"representation\":\"storage\"
                }
            }
         }" \
  "https://pbozhko.atlassian.net/wiki/rest/api/content/$confluence_page_id"
