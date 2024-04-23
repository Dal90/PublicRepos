$counter=1
$thisCount=150
while ($counter -le $thisCount) {
    $percentage=([math]::Round(($counter / $thisCount)*100))
    $counter++
    write-progress -activity "Searching" -status "$percentage% Complete" -percentComplete $percentage
    sleep 1
}