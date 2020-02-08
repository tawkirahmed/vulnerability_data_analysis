#!/bin/bash

counter_repositories=0

lib_name_original=( $(cut -d ',' -f1 smallSet.csv ) )
lib_id_original=( $(cut -d ',' -f2 smallSet.csv ) )
github_link_original=( $(cut -d ',' -f3 smallSet.csv ) )

for each_repo_name in "${lib_name_original[@]}"
do  
 #if [[ "$counter_repositories" != *"0"* ]]
 #then

   lines_csv_final[0]=lib_name,version,commit_hash,author,commentary,date,link,is_present

   # To remove " " from the gitHubs link
   dirty_link="${github_link_original[$counter_repositories]}" 
   prefix="\""
   suffix="\""
   github_link=${dirty_link#"$prefix"}
   github_link=${github_link%"$suffix"}

   # Clone gitHubs repository into folder with the same name as the repo id 
   git clone "${github_link}" "${lib_id_original[$counter_repositories]}"

   # We go inside the folder where is the repo cloned
   cd "${lib_id_original[$counter_repositories]}"

   # We download the full log, format: commit_hash, author, commit_commentary, commit_date
   git log --pretty="format:%H,%an,%f,%cI" > "${lib_id_original[$counter_repositories]}".csv

   commit_hash=( $(cut -d ',' -f1 "${lib_id_original[$counter_repositories]}".csv) )
   commit_author=( $(cut -d ',' -f2 "${lib_id_original[$counter_repositories]}".csv) )
   commit_commentary=( $(cut -d ',' -f3 "${lib_id_original[$counter_repositories]}".csv) )
   commit_date=( $(cut -d ',' -f4 "${lib_id_original[$counter_repositories]}".csv) )

   lines_log_counter=1

   for each_commit_hash in "${commit_hash[@]}"
   do	
     
    # To download package.json from each commit 
    git checkout "${each_commit_hash}" "package.json"

    is_version_present=0
  
    if [ -f package.json ]
    then
      mv "package.json" "${each_commit_hash}".json

      # Searching repo version
      while IFS= read -r line
      do
       IFS=':' read -r -a linesPackage <<< "$line"
       myString="${linesPackage[1]}"
       prefix=" \""
       suffix="\","
       foo=${myString#"$prefix"}
       foo=${foo%"$suffix"}
       if [[ "$line" == *"${each_repo_name}\""* ]]
       then 
        lines_csv_final[lines_log_counter]="${each_repo_name}","${foo}","${each_commit_hash}","${commit_author[$lines_log_counter]}","${commit_commentary[$lines_log_counter]}","${commit_date[$lines_log_counter]}","${github_link}",YES
        is_version_present=1
       fi
      done < "${each_commit_hash}".json
      rm "${each_commit_hash}".json
      if [ "$is_version_present" = 0 ]
      then
        lines_csv_final[lines_log_counter]="${each_repo_name}",,"${each_commit_hash}","${commit_author[$lines_log_counter]}","${commit_commentary[$lines_log_counter]}","${commit_date[$lines_log_counter]}","${github_link}",NO
      fi 
    fi
    ((lines_log_counter++))   
   done

   printf "%s\n" "${lines_csv_final[@]}" > "${lib_id_original[$counter_repositories]}".txt
   mv "${lib_id_original[$counter_repositories]}".txt "${lib_id_original[$counter_repositories]}".csv
   mv "${lib_id_original[$counter_repositories]}".csv ..
   cd ..
   unset lines_csv_final
   sudo rm -r "${lib_id_original[$counter_repositories]}"
 #fi 
 ((counter_repositories++))
done