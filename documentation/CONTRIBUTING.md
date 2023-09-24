# How to contribute
Follow the next steps to contribute your changes towards to project.

## Step 1: Fork the Repository of the module you want to work on

On the project's GitHub page, click the "Fork" button in the upper right corner. This creates a copy of the project's repository in your GitHub account.

## Step 2: Clone the Forked Repository

Clone the forked repository to your local machine using the git clone command. Replace <your-forked-repo-url> with the actual URL of your forked repository:

```bash
git clone <your-forked-repo-url>
```

## Step 3: Set Up Upstream Remote

Add a remote reference to the original project repository. This allows you to keep your forked repository in sync with any changes in the original repository:

```bash
git remote add upstream <original-repo-url>
```

## Step 4: Create a New Branch

Before making any changes, create a new branch for your contribution. This helps keep your changes isolated from the main branch:

```bash
git checkout -b <branch-name>
```

## Step 5: Make Changes

Make the desired changes or additions to the codebase in your local branch.

## Step 6: Test your changes

Test if your changes work. Make also sure that your changes don't break other functionality of the game.
   
## Step 7: Commit Changes

After making changes, commit them with a meaningful commit message:

```bash
git add .
git commit -m "Your descriptive commit message here"
```

## Step 8: Sync with Upstream

Before pushing your changes, sync your forked repository with the original repository to ensure you're working with the latest code:

```bash
git fetch upstream
git merge upstream/main  # or the appropriate branch
```

## Step 9: Resolve Conflicts (If Any)

If there are conflicts between your changes and the upstream changes, resolve them in your local repository.

## Step 10: Push Changes: Push your changes to your forked repository on GitHub

```bash
git push origin <branch-name>
```

## Step 11: Create a Pull Request (PR)

On your forked repository's GitHub page, you'll see a prompt to create a pull request from your branch to the original repository's main branch. Fill in the necessary details, including a descriptive title and a clear description of your changes.

If your changes consists of UI or art stuff make sure to add some screenshots to showcase them.

## Step 12: Engage in Discussions/Comments

Your PR might undergo review, feedback, and discussions. Be responsive and willing to make necessary changes based on feedback.

## Step 13: Finalize and Merge

Once your changes are approved and any requested changes are made, the project maintainers will merge your PR into the main repository.

## Step 14: Celebrate Your Contribution!

Congratulations, you've successfully contributed to an open-source project! Your changes are now part of the project's codebase.
