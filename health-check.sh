# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while read -r line
do
	echo "  $line"
	IFS='=' read -ra TOKENS <<< "$line"
	KEYSARRAY+=(${TOKENS[0]})
	URLSARRAY+=(${TOKENS[1]})
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

for (( index=0; index <= ${#KEYSARRAY[@]}; index++))
do
	key="${KEYSARRAY[index]}"
	url="${URLSARRAY[index]}"
	echo "  $key=$url"

	for i in 1 2 3 4; 
	do
		response=$(curl --write-out '%{http_code}' --silent --output /dev/null $url)
		if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 302 ] || [ "$response" -eq 307 ]; then
			result="success"
		else
			result="failed"
		fi
		
		echo "${key} return code: $result"
		
		if [ "$result" = "success" ]; then
			break
		fi
		sleep 5
	done
	
	dateTime=$(date +'%Y-%m-%d %H:%M')
	echo $dateTime, $result >> "logs/${key}_report.log"
	# By default we keep 2000 last log entries.  Feel free to modify this to meet your needs.
	echo "$(tail -2000 logs/${key}_report.log)" > "logs/${key}_report.log"
done
