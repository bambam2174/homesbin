# Bash getopt long options with values usage example

```sh
#!/bin/bash -e

ARGUMENT_LIST=(
    "arg-one"
    "arg-two"
    "arg-three"
)


# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arg-one)
            argOne=$2
            shift 2
            ;;

        --arg-two)
            argTwo=$2
            shift 2
            ;;

        --arg-three)
            argThree=$2
            shift 2
            ;;

        *)
            break
            ;;
    esac
done
```

**Note:** The `eval` in `eval set --$opts` is required as arguments returned by `getopt` are quoted.

## Example

```sh
$ ./getopt.sh --arg-one "apple" --arg-two "orange" --arg-three "banana"
```

## Reference
- http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt
- https://dustymabe.com/2013/05/17/easy-getopt-for-a-bash-script/
