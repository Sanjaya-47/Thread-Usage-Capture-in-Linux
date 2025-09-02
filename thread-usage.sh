#!/bin/bash
print_thread_usage() {

    local pid=$1
    local output_file="thread_usage_$(date "+%F-%T").txt"

    echo "Linux Version: $LINUX_VERSION" > "$output_file"
    echo "Clock Ticks: $CLOCK_TICKS" >> "$output_file"
    printf "%10s %10s %11s %10s %7s %15s %15s %15s %25s %20s      %-20s\n" \
        "PPID" "PID" "NUM_THREADS" "TID" "STATE" "CPU_USAGE" "UTIME" "STIME" "WCHAN" "VSIZE" "COMM" >> "$output_file"

    for tid_dir in /proc/"$pid"/task/*; do
        if [ -d "$tid_dir" ]; then
            tid=$(basename "$tid_dir")
            stat_file="$tid_dir"/stat
            if [ -f "$stat_file" ]; then
                read -r tmp_var1 rest < "$stat_file"
                read -r  -a rest_less_comm <<< "${rest##*)}"
                tmp_var2=${rest#*(}
                comm=${tmp_var2%)*}
                state=${rest_less_comm[0]}
                ppid=${rest_less_comm[1]}
                utime=${rest_less_comm[11]}
                stime=${rest_less_comm[12]}
                num_threads=${rest_less_comm[17]}
                starttime=${rest_less_comm[19]}
                vsize=${rest_less_comm[20]}
                if [ -f "$tid_dir"/wchan ]; then
                    read -r wchan < "$tid_dir"/wchan
                else
                    wchan="N/A"
                fi

                if command -v awk >/dev/null 2>&1; then
                    utime_seconds=$(awk "BEGIN {print $utime/$CLOCK_TICKS}")
                    stime_seconds=$(awk "BEGIN {print $stime/$CLOCK_TICKS}")
                    elapsed_time=$(awk "BEGIN {print ($UPTIME-($starttime/$CLOCK_TICKS))}")
                    cpu_time=$(awk "BEGIN {print ($utime+$stime)/$CLOCK_TICKS}")
                    if  awk "BEGIN {exit !($elapsed_time == 0)}"; then
                        cpu_usage=-999
                    else
                        cpu_usage=$(awk "BEGIN {print ($cpu_time*100/$elapsed_time)}")
                    fi
                else
                    utime_seconds=$(($utime / $CLOCK_TICKS))
                    stime_seconds=$(($stime / $CLOCK_TICKS))
                    elapsed_time=$((UPTIME_INT-($starttime/$CLOCK_TICKS)))
                    cpu_time=$((($utime+$stime)/$CLOCK_TICKS))
                    if [ "${elapsed_time:-0}" -eq 0 ]; then
                        cpu_usage=-999
                    else
                        cpu_usage=$(($cpu_time*100/$elapsed_time))
                    fi
                fi

                printf "%10d %10d %11ld %10d %7c %15.4f %15.4f %15.4f %25s %20d      %-20s\n" \
                    "$ppid" "$pid" "$num_threads" "$tid" "$state" "$cpu_usage" "$utime_seconds" "$stime_seconds" "$wchan" "$vsize" "($comm)" >> "$output_file"

            fi
        fi
    done
}

###############################################################################################################################

if [ "$#" -ne 3 ]; then
    echo "Incorrect number of arguments."
    echo "Correct usage: thread-usage.sh <PID> <Number of Dumps> <Time Interval between Dumps in seconds>"
    exit 1
fi

readonly LINUX_VERSION=$(uname -r)
readonly CLOCK_TICKS=$(getconf CLK_TCK)

read -r UPTIME _ < /proc/uptime
readonly UPTIME
readonly UPTIME_INT=${UPTIME%.*}

readonly arg_pid=$1
readonly arg_num_dumps=$2
readonly arg_interval=$3

for (( i=1; i<=arg_num_dumps; i++)); do
    echo "Capturing dump $i"
    print_thread_usage "$arg_pid"
    sleep "$arg_interval"
done

echo "Thread usage capture completed."