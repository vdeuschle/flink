#!/bin/bash

SPLUNK_MAJOR_VERSION="1.13"

git clone https://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@github.com/splunk/flink.git

cd flink
git pull
git branch

echo "------ cloned splunk/flink repo"

# Add upstream which points to Flink repo and update splunk repo's master
git remote add upstream https://github.com/apache/flink.git

echo "------ 1"
git fetch
git pull upstream master
#git push

echo "------ Able to pull from upstream master"

#get all tags from upstream
git pull --tags upstream

tags=`git ls-remote --tags https://github.com/apache/flink.git | grep release | grep -Ev 'rc|{}'`
# echo "$tags"
echo "------ Able to pull from tags from upstream"


# get flink release tags
release_tags=()
for tag in $tags; do

    if [[ $tag == *"release"* ]]; then

        value=`echo $tag | awk -F/ '{print $NF}' | awk -F- '{print $2}' | grep $SPLUNK_MAJOR_VERSION`
        release_tags+=($value)
    else
        continue
    fi
done

latest_release_tag_version=${release_tags[${#release_tags[@]} - 1]}
latest_upstream_release_tag="release-$latest_release_tag_version"
echo "Latest release tag: $latest_upstream_release_tag"


# get splunk release branches
splunk_branches=`git branch -r`

splunk_release_branches=()
for branch in $splunk_branches; do

    if [[ $branch == *"release"* ]]; then
        value=`echo $branch | awk -F- '{print $2}' | grep $SPLUNK_MAJOR_VERSION`
        splunk_release_tags+=($value)
    else
        continue
    fi
done

current_splunk_release_tag_version=${splunk_release_tags[${#splunk_release_tags[@]} - 1]}
current_splunk_release_tag="release-$current_splunk_release_tag_version-splunk"
echo "Current Splunk release tag: $current_splunk_release_tag"

latest_splunk_release_tag="release-$latest_release_tag_version-splunk"
echo "Latest splunk release tag: $latest_splunk_release_tag"

old_upstream_release_tag="release-$current_splunk_release_tag_version"
echo "Old Splunk equivalent upstream release tag: $old_upstream_release_tag"


if [[ $latest_release_tag_version = $current_splunk_release_tag_version ]]; then
    echo "Latest minor release tag matches with the current splunk release tag"
else
    echo "Latest minor release tag doesn't match with the current splunk release tag"
    #creates a splunk specific release branch
    git fetch upstream --tags
    git checkout -b $latest_splunk_release_tag $latest_release_tag

    # origin should be pointing to git@github.com:splunk/flink.git
#    git push origin $latest_splunk_release_tag

    # finds the rebased from the release tag version
    base=`git log origin/$current_splunk_release_tag --grep="Commit for release $current_splunk_release_tag_version" --format="%H"`
    echo "Most recent common ancestor commit: $base \n"

    # gets the list of commits that have been added after the branch has been cutover
    diff=`git rev-list --ancestry-path $base..origin/$current_splunk_release_tag --reverse`
    echo "List of commits:\n$diff \n"

    # cherry pick commits based on requirement
    for commit in $diff; do

        commit_info=`git rev-list --format=%B --max-count=1 $commit`

        echo "$commit_info"

        if [[ $commit_info = *"modify flink versioning"* ]]; then
            continue
        fi

        result=`git cherry-pick $commit`
        echo "$result"

        if [[ $result = *"CONFLICT"* ]]; then
            echo "Conflict occured. Please resolve manually"
            echo "Conflict occurred while cherry-picking for commit-sha: $commit and commit description: $commit_info . Please resolve manually" | mail -s "Conflict occurred while cherry-picking commits from $current_splunk_release_tag to $latest_splunk_release_tag" srampally@splunk.com
            exit
        fi
    done

    # modify flink versioning to append splunk-SNAPSHOT
    cd tools
    sh change-version.sh $latest_release_tag
    cd ..
    git add .
    git commit -m "modify flink versioning"

#    git push origin $latest_splunk_release_tag

    echo "Successfully cherry-picked all commits to new tag $latest_splunk_release_tag and modified to splunk specific versioning" | mail -s "Successfully cherry-picked all commits from $current_splunk_release_tag to $latest_splunk_release_tag" srampally@splunk.com
fi
