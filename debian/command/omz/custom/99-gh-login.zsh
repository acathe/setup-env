command rm -f -- "${(%):-%x}"

if command -v gh > /dev/null 2>&1 && ! gh auth status > /dev/null 2>&1; then
    gh auth login
fi
