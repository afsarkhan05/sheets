# Git

```bash
ssh-agent $(ssh-add ~/.ssh/private_key; git clone git_url_to_clone .)
```

New Repo Push

1. `git init -b main`
2. Create repo in github without .gitignore and readme file
3. `git remote add origin git@github.com:user_name/repo_name.git`
4. `git add .`
5. `git commit -m 'commit message'`
6. if needed create main branch as it will be master
7. `git push origin main`

Working with multiple user

.ssh/config

```sshconfig
# Personal GitHub account
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/pvt_1

# Work GitHub account
Host github.com-client
    HostName github.com
    User git
    IdentityFile ~/.ssh/pvt_2
```

### 1st User

1. `git clone git@github.com:{user}}/{repo}.git`

2nd User

2. `git clone git@github.com-client:{user}}/{repo}.git`

Make sure to set user.name and user.email before pushing to avoid wrong git user in commit

```bash
git config --global user.name "1st_user"
git config --global user.email "1st_email"

git init
git commit -m "test commit"
git push
```

## More Information

```bash
#check remove url of repo
git remote -v

#set remote url to repo
git remote set-url origin git@github.com:username/repo.git

# Set user name of github account to come in commit
git config --global user.name "1st_user"
git config --global user.email "1st_email"
```


## GIT top commands


### Setup & Repositories

```bash
# Sets the author name and email attached to your commits
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Initializes a brand-new local Git repository in your current project folder.
git init

# Downloads an existing remote repository and its full history onto your computer.
git clone <url>
```


### Staging & Committing

```bash

# Shows which files are modified, staged for the next commit, or untracked.
git status

# Moves specific files (or all changed files) from your working directory into the staging area.
git add <file> 
# or 
git add .

# Saves your staged changes as a permanent snapshot in the local repository history.
git commit -m "Message"

# Displays line-by-line unstaged changes between your working files and the last commit.
git diff

```

### Branching & Merging

```bash
# Lists all local branches in your repository and highlights the one you are currently on.
git branch

# Creates a new branch and immediately switches to it.
git switch -c <branch> 

# or create new branch
git checkout -b <branch> 

# Switches your working directory to an existing branch.
git switch <branch> 

# or 

git checkout <branch>

# Combines the changes from the specified branch into your currently active branch.
git merge <branch>

```

### Syncing & History

```bash
# Fetches changes from the remote repository and merges them into your current local branch.
git pull

# Uploads your local commits to the remote repository (such as GitHub or GitLab).
git push

# Displays a compact, chronological list of past commits and their IDs
git log --oneline
```