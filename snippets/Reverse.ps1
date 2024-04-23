# This was just a bit of a brain exercise --
# without using the 'net could I reverse the order of letters?
# I'd have to concede no -- but I pretty quickly could reverse
# the order of words in a sentence. 

# Be interesting if in the future I can do the actual reverse
# letters

PS> $myvar="Hello World"        
PS> $myvar2=($myvar).split''
ParserError: 
Line |
   1 |  $myvar2=($myvar).split''
     |                        ~~
     | Unexpected token '''' in expression or statement.
PS> $myvar2=($myvar).split('')
PS> $myvar2
Hello World
PS> $myvar2=($myvar).split()  
PS> $myvar2                 
Hello
World
PS> $count=($myvar2).count                                                                       
PS> while ($counter -ge 0t) {$myvar[$count]; $counter=$counter-1}         
ParserError: 
Line |
   1 |  while ($counter -ge 0t) {$myvar[$count]; $counter=$counter-1}
     |                     ~
     | You must provide a value expression following the '-ge' operator.
PS> while ($counter -ge 0) {$myvar[$count]; $counter=$counter-1} 
PS> while ($counter -ge 0) {$myvar2[$count]; $counter=$counter-1}
PS> $myvar2[0]              
Hello
PS> while ($counter -ge 0) {$myvar2[$counter]; $counter=$counter-1}
PS> while ($counter -ge 0) {$myvar2[$($counter)]; $counter=$counter-1}
PS> $counter=($myvar2).count                                          
PS> while ($counter -ge 0) {$myvar2[$($counter)]; $counter=$counter-1}
World
Hello