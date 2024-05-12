# First we need an string...
    $myvar="Hello Beautiful World!  K111111 (KB222222) (KB3333333) (KB4444444)"

# Last Instances of (KB<anynumber>) using "+$";
# \d* and [0-9]* are equivelant
    ($myvar | select-string -pattern '\(KB\d*\)+$').matches.groups[0].value
    (KB4444444)

# Now let's grab the second instance of (KB<anynumbers)
    ($myvar | select-string -pattern '(?:.*?(\(KB\d*\))){2}').matches.groups[1].value
    (KB3333333)

# We can walk through the entire string for all matches.
# Note the change to using double " " for the regex instead of single ' ' to allow for variable expansion
    $count=1
    $more=$true
    while ($more -eq $true) {
	    try {
	    	($myvar | select-string -pattern "(?:.*?(\(KB\d*\))){$($count)}").matches.groups[1].value
		    $count++
	    }
	    catch {
	    	$more = $false
	    }
    }

    # As a one-liner:
    $count=1; $more=$true; while ($more -eq $true) { try { ($myvar | select-string -pattern "(?:.*?(\(KB\d*\))){$($count)}").matches.groups[1].value; $count++ } catch { $more = $false }}

# Above, read into an array:
    PS > $results=@(); $count=1; $more=$true; while ($more -eq $true) { try { $results+=(($myvar | select-string -pattern "(?:.*?(\(KB\d*\))){$($count)}").matches.groups[1].value); $count++ } catch { $more = $false }}
    PS > $results.count
    3
    PS > $results
    (KB222222)
    (KB3333333)
    (KB4444444)
    
    # Remember that elements in an array are counted from [0] 
    PS > ($results)[0]
    (KB222222)
    PS > ($results)[1]
    (KB3333333)
    PS > ($results)[2]
    (KB4444444)

    # So let's change up our array -- notice KB11 and KBG88 are not in () so shouldn't match.
    PS > $myvar="Hello Beautiful World!  KB11 (KB22) (KB33) (KB44) (KB55) (KB66) (KB77) KB88 (KB99)"
    PS > $results=@(); $count=1; $more=$true; while ($more -eq $true) { try { $results+=(($myvar | select-string -pattern "(?:.*?(\(KB\d*\))){$($count)}").matches.groups[1].value); $count++ } catch { $more = $false }}
    PS > $results.count                                                                                                                                                   
    7
    PS > $results
    (KB22)
    (KB33)
    (KB44)
    (KB55)
    (KB66)
    (KB77)
    (KB99)
    # So if we want to see the 5th matching group:  
    PS > ($results)[4]
    (KB66)


