#!/bin/sh

if ! test -t 1; then
	echo "please launch in a terminal"
	exit
fi

tester_dir="$(dirname "$0")"

original_tty_state=$(stty -g)

NC="\033[0;0m"
BOLD="\033[1m"
ITALIC="\033[3m"
UNDER="\033[4m"

BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

B_BLACK="\033[0;40m"
B_RED="\033[0;41m"
B_GREEN="\033[0;42m"
B_YELLOW="\033[0;43m"
B_BLUE="\033[0;44m"
B_MAGENTA="\033[0;45m"
B_CYAN="\033[0;46m"
B_WHITE="\033[0;47m"

BBLACK="\033[0;90m"
BRED="\033[0;91m"
BGREEN="\033[0;92m"
BYELLOW="\033[0;93m"
BBLUE="\033[0;94m"
BMAGENTA="\033[0;95m"
BCYAN="\033[0;96m"
BWHITE="\033[0;97m"

B_BBLACK="\033[0;100m"
B_BRED="\033[0;101m"
B_BGREEN="\033[0;102m"
B_BYELLOW="\033[0;103m"
B_BBLUE="\033[0;104m"
B_BMAGENTA="\033[0;105m"
B_BCYAN="\033[0;106m"
B_BWHITE="\033[0;107m"

BACKGROUND="\033[48;5;26m"

IFS=

if [ "`echo -n`" = "-n" ]; then
	n=""
	c="\c"
else
	n="-n"
	c=""
fi

nb_lines=`tput lines`
nb_cols=`tput cols`

UPDATE="\33[A"

exit_func () {
	echo $n $NC$c
	echo $'\e'"[?1000;1006;1015l"
	stty $original_tty_state
	tput cup 0 0
	tput el
	tput cnorm
	echo 'End of run'
	exit
}

redraw () {

	nb_lines=`tput lines`
	nb_cols=`tput cols`

	s=`printf '%*s' $nb_cols`
	tput cup 0 0
	tput ed

	echo $n "$BACKGROUND$c"
	for (( i = 0; i < $nb_lines - 1; i++ )); do
		if (( i == 0 || i == $nb_lines - 2 )); then
			echo $n "+$c"
			echo $n ${s:2}$c | tr " " "-"
			echo "+"
		else
			echo $n "|$c"
			echo $n ${s:2}$c
			echo "|"
		fi
	done
}

handle () {
	read -s -n 1 bracket
	if [[ "$bracket" == "[" ]]; then
		# echo $bracket
		first_nb=
		second_nb=
		third_nb=
		while read -s -n 1 nb; do
			if [ "$nb" -ge 0 ] 2>/dev/null
			then
				first_nb+=$nb
			else
				if [[ $first_nb == "" ]]; then
					return
				else
					break
				fi
			fi
		done
		while read -s -n 1 nb; do
			if [ "$nb" -ge 0 ] 2>/dev/null
			then
				second_nb+=$nb
			else
				break
			fi
		done
		while read -s -n 1 nb; do
			if [ "$nb" -ge 0 ] 2>/dev/null
			then
				third_nb+=$nb
			else
				break
			fi
		done
		if (( third_nb == nb_lines )); then
			return
		fi
		let second_nb--
		let third_nb--
		tput cup $third_nb $second_nb
		if (( first_nb == 32 )); then
			if (( $third_nb == 1 && $second_nb <= 5 && second_nb >= 1 )); then
				tput cup 1 1
				echo $n $RED$BACKGROUND"hello"$c
			else
				echo $B_RED" "$NC
			fi
		elif (( first_nb == 35 )); then
			if (( $third_nb == 1 && $second_nb <= 5 && second_nb >= 1 )); then
				tput cup 1 1
				echo $n $GREEN$BACKGROUND"hello"$c
			else
				echo $B_GREEN" "$NC
			fi
		fi
	fi
}

tput civis
trap 'redraw' WINCH
trap "exit_func" INT

echo $'\e'"[?1000;1006;1015h"

clear

# if [[ -z $1 ]]; then
# 	echo "usage"
# 	exit
# fi

param=$1
s=`printf '%*s' $((nb_cols - 2))`

echo $n "$BACKGROUND$c"
for (( i = 0; i < $nb_lines - 1; i++ )); do
	if (( i == 0 || i == $nb_lines - 2 )); then
		echo $n "+$c"
		echo $n $s$c | tr " " "-"
		echo "+"
	else
		echo "|$s|"
	fi
done

tput cup 1 1
echo "hello"
while read -s -n 1 esc; do
	if [[ "$esc" == $'\e' ]]; then
		handle
	fi
done

exit_func
