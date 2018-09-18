#!/bin/bash -e

# create dummy input lines (think output of say, ls)
read -d '' INPUT_LINES <<EOF
/path/to/first file
/path/to/second file
/path/to/third file
EOF


# without IFS
for item in $(echo "$INPUT_LINES"); do
	echo "$item"
done

echo


# with IFS
IFS=$'\n'
for item in $(echo "$INPUT_LINES"); do
	echo "$item"
done

# reset back to default value
unset IFS
