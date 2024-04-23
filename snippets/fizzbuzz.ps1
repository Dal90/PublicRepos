param (
	[parameter(mandatory)]$number
)

# This wouldn't be needed if the script is standalone,
# but is helpful in the vsCode terminal and would be
# needed if you were making a loop of this
	clear-variable -scope script -name myVar* 

if (($number %3) -eq 0) {$myVar3="Fizz"}
if (($number %5) -eq 0) {$myVar5="Buzz"}
$fizzbuzz=("$($myVar3)$($myVar5)").trim()

if ($fizzbuzz) {
	$fizzbuzz
} else {
	$number
}