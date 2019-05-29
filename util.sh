#!/bin/sh

tester_dir="$(dirname "$0")"
tmp_dir="$tester_dir/tmp"
mkdir -p $tmp_dir

input_copied () {
	nb_lines=`wc -l < $1`
	head -n $nb_lines $2 > $tmp_dir/start_of_sol_file$3
	diff "$tmp_dir/start_of_sol_file$3" $1 >/dev/null 2>&1
	if (( $? != 0 )); then
		echo "stdin not well copied"
	fi
	rm -f "$tmp_dir/start_of_sol_file$3"
}