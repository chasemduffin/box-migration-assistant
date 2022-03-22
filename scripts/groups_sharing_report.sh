#!/bin/bash

### Example Usage
### ./groups_sharing_report.sh "My Group" "123456789"

group_search_string=($1)                                                                        # partial matching group name(s)
query_user_id=($2)                                                                              # user ID of the Box user to search with                                                                              

group_ids=$(box groups --filter $group_search_string --json | jq '.[].id' --raw-output)         # get the IDs of the matching groups

# while there are more group IDs, iterate over each
while IFS= read -r group_id; do
  collaboration_ids=$(box groups:collaborations $group_id --json | jq '.[].id' --raw-output)    # get all of the the collaboration ID strings
  while IFS= read -r collaboration_id; do                                                       # while there are more collaboration IDs, iterate over each
    collaboration=$(box collaborations:get $collaboration_id --as-user $query_user_id --json)   # get the collaboration as a JSON representation
    collaboration_type=$(echo $collaboration | jq '.item.type' --raw-output)                    # parse the item type, file or folder
    collaboration_item_id=$(echo $collaboration | jq '.item.id' --raw-output)                   # parse the item ID
    if [[ $collaboration_type == "folder" ]]; then                                              # if the item is a folder
      item=$(box folders:get $collaboration_item_id --as-user $query_user_id --json)            # get the folder as a JSON representation
    else                                                                                        # else the item is a file
      item=$(box files:get $collaboration_item_id --as-user $query_user_id --json)              # get the file as a JSON representation
    fi
    name=$(echo $item | jq '.name' --raw-output)                                                # parse the item name, owner, and file path
    owner=$(echo $item | jq '.owned_by.name' --raw-output)
    item_path=$(echo $item | jq '.path_collection.entries[].name' --raw-output | tr '\n' '/' | tr -d ',')
    echo $name, $owner, $item_path, $collaboration_item_id,                                     # write the item attributes to stdout as csv
  done <<< "$collaboration_ids"
done <<< "$group_ids"
