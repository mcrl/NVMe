git filter-branch --env-filter '
if [ "$GIT_COMMIT" = "$(git rev-list -n 1 --before="2023-09-12" master)" ]; then
    export GIT_AUTHOR_DATE=$(cat sorted_dates.txt)
    export GIT_COMMITTER_DATE=$(cat sorted_dates.txt)
fi
' --tag-name-filter cat -- --branches --tags
