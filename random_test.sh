#!/bin/sh

if [ "`echo -n`" = "-n" ]; then
	n=""
	c="\c"
else
	n="-n"
	c=""
fi

tester_dir="$(dirname "$0")"
random_dir_old=$tester_dir/.random_test
rm -rf $random_dir_old
random_dir=$tester_dir/random_test
mkdir -p $random_dir

source $tester_dir"/util.sh"

single_test () {

	sleep $((($1 - 1) % 4))
	file_base=$random_dir/big_sup$1
	current_map=$file_base".txt"
	current_sol=$file_base"_solved.txt"
	current_result=$file_base"_result.txt"
	./$tester_dir/generator --big-superposition > $current_map
	current_map_links=`cat $current_map | grep -E ".+-.+"`
	start_time=`ruby -e 'puts Time.now.to_f'`
	./$tester_dir/timeout 15 ./$tester_dir/lem-in < $current_map > $current_sol
	end_time=`ruby -e 'puts Time.now.to_f'`
	runtime=`echo $end_time - $start_time | bc | sed "s/^\./0./"`
	cat /dev/null > $current_result
	if (( $? == 124 )); then
		echo "more than 15 seconds" >> $current_result
		continue
	fi

	input_copied $current_map $current_sol $1 >> $current_result

	nb_rooms=`grep -E "^[^L#].* [0-9]+ [0-9]+$" $current_map | wc -l`

	nb_ants=`grep -E "^[0-9]+$" $current_map`
	start=`grep -A 1 "^##start$" $current_map | sed "s/##start//" | tr -d '\n' | cut -d' ' -f1`
	end=`grep -A 1 "^##end$" $current_map | sed "s/##end//" | tr -d '\n' | cut -d' ' -f1`

	if [[ -z $start || -z $end ]];then
		echo "no start or end room" >> $current_result
	else

		declare -a pos_ant=()
		for (( i = 0; i < nb_ants; i++ )); do
			pos_ant+=($start)
		done

		paths=""
		i=0
		declare -i id_ant
		# echo $start
		for line in `grep -E "^L" $current_sol`; do
			# echo line $i
			IFS=" L"
			for ((j=0; j<nb_ants; j++)); do
				has_moved[$j]=0
			done
			for move in `echo $line`; do
				id_ant=move-1
				next_room=${move##*-}
				# echo $paths | grep -m 1 "${pos_ant[$id_ant]} $next_room"
				if [[ $paths != *"${pos_ant[$id_ant]} $next_room"* ]]; then
					if [[ $current_map_links == *"${pos_ant[$id_ant]}-$next_room"* || $current_map_links == *"$next_room-${pos_ant[$id_ant]}"* ]]; then
						paths+="${pos_ant[$id_ant]} $next_room\n"
					else
						echo "$next_room and ${pos_ant[$id_ant]} are not linked on play $i" >> $current_result
					fi
				fi
				pos_ant[$id_ant]=$next_room
				if (( has_moved[$id_ant] == 1 ));then
					echo "ant $((id_ant+1)) moved twice on play $i" >> $current_result
				else
					has_moved[$id_ant]=1
				fi
			done
			IFS=$'\n'
			all_pos=`echo "${pos_ant[@]}" | tr ' ' '\n' | sed "s/$start//g" | sed "s/$end//g"`
			# all_pos=`echo ${pos_ant[@]} | sed "s/$start//g" | sed "s/$end//g" | tr " " "\n"`
			nb_uniq_lines=`echo $all_pos | tr ' ' '\n' | sort -u | wc -l`
			nb_lines=`echo $all_pos | tr ' ' '\n' | wc -l`
			if (( nb_uniq_lines != nb_lines ));then
				ant_idx=0
				for pos in `echo ${pos_ant[@]} | tr ' ' '\n' | sed "s/$start//g" | sed "s/$end//g"`; do
					# echo $pos
					c=0
					other_idx=0
					for other_pos in ${pos_ant[@]}; do
						if [[ $pos == $other_pos ]]; then
							if (( c == 0 && other_idx != ant_idx )); then
								let ant_idx++
								continue
							fi
							let c++
						fi
						let other_idx++
					done
					if (( c > 1 )); then
						echo "$c ants in room '$pos' at line $((i + 2 + `wc -l < $current_map`))" >> $current_result
					fi
					let ant_idx++
				done
			fi
			let i++
		done
		if [[ -n `echo "${pos_ant[@]}" | tr ' ' '\n' | sed "s/$end//g"` ]]; then
			echo "not all ant arrived" >> $current_result
		fi
	fi
	if [[ -z `cat $current_result` ]]; then
		echo "No error found !" >> $current_result
		echo "Done in "$runtime" seconds ($((5 - `echo $runtime | sed "s/\..*//"` / 3))/5)" >> $current_result
		expected=`grep -E -m 1 "^#Here is the number of lines required: [0-9]+$" $current_map | grep -Eo "[0-9]+"` >> $current_result
		differ=$((expected-i))
		if (( i - expected <= 0 )); then
			grade=5
		elif (( i - expected <= 2 )); then
			grade=4
		elif (( i - expected <= 10 )); then
			grade=3
		else
			grade=0
		fi
		echo $n "$i vs $expected, ${differ#-} $c" >> $current_result
		(( expected > i )) && echo $n "below$c" >> $current_result || echo $n "above$c" >> $current_result
		echo " the generator ($grade/5)" >> $current_result
		printf "%3d |     ok |  $((5 - `echo $runtime | sed "s/\..*//"` / 3))/5 |   $grade/5\n" $1
	else
		printf "%3d | failed |  0/5 |   0/5\n" $1
	fi
}

random_test () {

	trap "exit" INT TERM ERR
	trap "kill 0" EXIT

	rm -rf $random_dir/*

	IFS=$'\n'

	if (( $# > 0 )); then
		nb_tests=$1
	else
		nb_tests=5
	fi

	echo " id | result | time | moves"
	echo "---------------------------"
	for (( test_id = 1; test_id <= nb_tests; test_id++ )); do

		single_test $test_id &
		if (( test_id % 4 == 0)); then
			wait
		fi
	done
	wait
	echo "---------------------------"
	grade=5
	runtime=5
	for file in `ls -1 $random_dir | grep "result"`; do
		tmp=`grep seconds $random_dir/$file||echo`
		if [[ -z $tmp ]];then
			grade=0
			runtime=0
			break
		fi
		if (( ${tmp: -4:1} < grade )); then
			grade=${tmp: -4:1}
		fi
		tmp=`grep generator $random_dir/$file||echo`
		if [[ -z $tmp ]];then
			grade=0
			runtime=0
			break
		fi
		if (( ${tmp: -4:1} < runtime )); then
			runtime=${tmp: -4:1}
		fi
	done
	if (( grade == 0 || runtime == 0 )); then
		str="failed"
	else
		str="    ok"
	fi
	echo "tot | $str |  $grade/5 |   $runtime/5"
}

random_test "$@"
