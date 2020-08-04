 git filter-branch --force --index-filter "git rm --cached --ignore-unmatch cpp/ -r" --prune-empty --tag-name-filter cat -- --all
