#!/usr/bin/env bash
# worgs.sh by Lee Bigelow
# Word guessing game. Wordle like game for the terminal?
# Use, copy, distribute and modify at will.

scorefile="$HOME/.config/worgs-scores"
numw=$(grep -E '^[a-z]{5}$' /usr/share/dict/words | wc -l)
word=$(grep -E '^[a-z]{5}$' /usr/share/dict/words | shuf -n 1)
word=${word^^} # upper case it
# using arrays for easy elemnet changing
avail=({A..Z})
apres=() # array of present strings from past tries
corr=(. . . . .) # correct letters array
score=100

for attempt in {1..6}; do
	clear
	pnts=$(( ($attempt<6) ? 5*$attempt : 25 ))
	echo "A 5 letter word out of $numw available has been chosen."
	echo "Can you guess the word? You've got "$(( 7-$attempt ))" tries left!"
	echo "Your current score is: $score"
	echo "This round an incorrect guess will lose you $pnts points."
	echo
	echo "Available: letters are removed when tried but not found in the word"
	echo "  Present: letter is in the word but not in that position"
	echo "  Correct: letter is in the correct position"
	echo
	echo "GOOD LUCK!"
	echo "Score: $score"
	echo "Available: ${avail[@]}"
	# print collected present strings from array
	# iterate by index get associated attempt number
	for presind in ${!apres[@]}; do
		let "try=$presind+1"
		echo "Present $try: ${apres[$presind]}"
	done
	# using printf to eliminate spaces between array elements
	printf "  Correct: %s%s%s%s%s\n" ${corr[@]}

	while true; do
		read -e -p "  Guess $attempt: " guess
		if (( ${#guess} != 5 )); then
			echo "Guess needs to be 5 letters, please try again."
		else
			guess=${guess^^} # make uppercase
			break
		fi
	done

	if [[ $guess == $word ]]; then
		echo
		echo "YOU WIN !!!!"
		echo "Final score: $score"
		echo "You correctly guessed $guess on the $attempt try!"
		echo "Go treat yourself, you deserve it!"
		date +"%F %T  $word ($score)" >> $scorefile
		echo
		echo "Past scores:"
		cat "$scorefile"
		exit
	fi
	
	# remove amount from score for incorrect guess
	let "score-=$pnts"

	# clear present characters array for this guess
	pres=(. . . . .)

	# iterate over character indexes in guess
	for c in {0..4}; do
		letter=${guess:$c:1}
		inword=${word%%"$letter"*}
		inword=${#inword}
		if [[ $letter == ${word:$c:1} ]]; then
			# Correct letter and positon
			corr[$c]=$letter
		elif (( $inword < 5 )); then
			# Present but wrong position, add to present chars array at this index
			pres[$c]=$letter
		else
			# not present, remove letter from available array
			# iterate over array indices
			for aind in ${!avail[@]}; do
				if [[ ${avail[$aind]} == $letter ]]; then
					avail[$aind]="_"
					break
				fi
			done
		fi
	done

	# convert present array for this guess to string and store in array
	presstr=$(printf "%s%s%s%s%s" ${pres[@]})
	apres+=("$presstr")
done

echo
echo "Ouch, no joy :("
echo "The word was: $word"
echo "Better luck next time."

date +"%F %T  $word ($score)" >> $scorefile
echo
echo "Past scores:"
cat "$scorefile"

