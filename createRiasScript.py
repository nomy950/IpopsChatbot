#
#
# main() will be run when you invoke this action
#
# @param Cloud Functions actions accept a single parameter, which must be a JSON object.
#
# @return The output of this action, which must be a JSON object.
#
#
import sys
from github import Github

def main():
    
    git_token = "<git-token>"






    region = "dal12"
    env = "preprod"
    command = "kubectl get pods -A"
    issue_number="82"
    script_name = 'rias_scripts/dev_rias_'+issue_number+'.sh'

    #retrieving all files from repo
    my_git = Github(git_token)
    repo = my_git.get_repo("nomy950/IpopsChatbot")
    all_files = []
    contents = repo.get_contents("")
    while contents:
        file_content = contents.pop(0)
        if file_content.type == "dir":
            contents.extend(repo.get_contents(file_content.path))
        else:
            file = file_content
            all_files.append(str(file).replace('ContentFile(path="','').replace('")',''))
    

    #create a driver file to execute script for pipeline stage
    with open ('driver.txt', 'w') as rsh:
        rsh.write('''\
    #! /bin/bash
    #set -u
    issue_number={issue_number}
    #sudo sh  ${{d_api_key}}
    #export JOB_LOG="$PIPELINE_LOG_URL"
    #echo ${{JOB_LOG}}
    '''.format(issue_number=issue_number))

    f2=open("driver.txt", "r")
    if f2.mode == 'r':
        content2 =f2.read()
        print(content2)

    git_file_1 = "driver.txt"
    if git_file_1 in all_files:
        contents = repo.get_contents(git_file_1)
        repo.update_file(contents.path, "committing files", content2, contents.sha, branch="main")
        print(git_file_1 + ' UPDATED')
    else:
        repo.create_file(git_file_1, "committing files", content2, branch="main")
        print(git_file_1 + ' CREATED')


    #create a script file
    with open ('run.sh', 'w') as rsh:
        rsh.write('''\
    #! /bin/bash
    ibmcloud login --apikey $1 -r kr-seo
    clusterName=`ibmcloud ks clusters | grep {region} | grep {env} | awk '{{ print $1 }}'`
    ibmcloud ks cluster config -c $clusterName
    echo "<Logs_Start>"
    {command}
    echo "<Logs_End>"
    '''.format(region=region,env=env,command=command))


    f=open("run.sh", "r")
    if f.mode == 'r':
        contents =f.read()
        print(contents)

    script_name = 'dev_rias_'+issue_number+'.sh'
    # Upload to github
    git_prefix = 'rias_scripts/'
    git_file = git_prefix + script_name
    status = repo.create_file(git_file, "committing files", contents, branch="main")
    print(status)
    if not status["content"]:
        print(git_file + ' CREATION FAILED!')
    else:
        print(git_file + ' CREATED!')

    
    #rename the file with corresponding issue number
    
    #push the file to repo
    
    
    return { 'message': 'Hello world' }


main()
