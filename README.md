# Thread-Usage-Capture-in-Linux
Thread usage capture in Linux with minimal commands (No ps)

## Usage
thread-usage.sh <PID> <Number of Usage Dumps> <Time Interval Between Two Dumps in Seconds>
Ex: thread-usage.sh 1234 5 1

## When to Use
Some systems use Linux distributions with minimal commands available. In such systems, most of the time ps and top or similar command line tools are not available. 
This script derives useful thread-usage information from the raw data available in thr /proc virtual file system of Linux.

## For More Info

For more information on /proc file system, see: https://man7.org/linux/man-pages/man5/proc.5.html


