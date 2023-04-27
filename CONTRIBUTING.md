# Contributing to multiring.zig

Thank you for your interest in improving this project! We welcome contributions of all types and sizes from everyone.

## Code of conduct

The community around this project has a [code of conduct] that all participants are expected to understand and follow. We believe that enforcing a code of conduct is crucial for cultivating [diversity, equity, inclusion and belonging][DEIB] as well as [psychological safety]. These are necessary ingredients for a healthy and self-sustaining community that generates value as well as fulfilling experiences for its participants.

## Table of contents

- [Code of conduct](#code-of-conduct)
- [Ways to contribute](#ways-to-contribute)
- [Opening an issue](#opening-an-issue)
- [Contribution workflow](#contribution-workflow)
  - [Local development requirements](#local-development-requirements)
  - [Claiming an issue](#claiming-an-issue)
  - [Getting the source code](#getting-the-source-code)
  - [Keeping your local repository up to date](#keeping-your-local-repository-up-to-date)
  - [Preparing your local repository for work](#preparing-your-local-repository-for-work)
  - [Committing your changes locally](#committing-your-changes-locally)
  - [Handling merge conflicts](#handling-merge-conflicts)
  - [Creating a pull request](#creating-a-pull-request)
  - [Receiving feedback](#receiving-feedback)
  - [Approval and attribution](#approval-and-attribution)
- [Project practices and guidelines](#project-practices-and-guidelines)
  - [Tracking and closing issues](#tracking-and-closing-issues)
  - [Flavors of code](#flavors-of-code)
  - [Formatting conventions](#formatting-conventions)
  - [Branching strategy](#branching-strategy)
  - [Commit messages](#commit-messages)
  - [Commit hooks](#commit-hooks)
  - [Continuous integration](#continuous-integration)
  - [Reviewing pull requests](#reviewing-pull-requests)
  - [Pull request approval criteria](#pull-request-approval-criteria)
  - [Attribution](#attribution)
  - [Versioning scheme](#versioning-scheme)
  - [Changes to our process](#changes-to-our-process)

## Ways to contribute

- [🐛 Report a bug or reproduce an existing bug][bugs]
- [⚙️  Spot a chore][operations]
- [🎁 Suggest a feature][enhancements]
- [🔩 Suggest a refactor][enhancements]
- [📚 Suggest improvements to documentation][documentation]
- [🏷️ Comment or work on an existing issue][issues]
- [💬 Start a discussion][discussions]
- [🕹️ Use multiring.zig][use multiring.zig] or write about it
- [🛠️ Apply for maintainership][governance]

## Opening an issue

An issue represents a logical unit of work on the project. [Opening an issue][open an issue] is the simplest way to contribute to the project and sets the stage for a potential incremental improvement.

When we open an issue, we are effectively requesting a constructive discussion about whether some work should be done on the project. We open issues without expectation of a particular outcome. We aim to discover, through collaboration, an outcome that adds incremental value to both the project itself and the community around it. In working towards this goal, we open our minds eagerly to new ideas without becoming attached to or identifying with them.

See also: [Tracking and closing issues](#tracking-and-closing-issues)

## Contribution workflow

### Local development requirements

To work on multiring.zig, you’ll need some or all of following software:

- [Git] 2.9 or newer
- [Zig] 0.10.1, for work on the multiring data structure
- [ShellCheck] 0.8, for [Git hook][githooks] development
- [yamllint] 1.31, for [GitHub issue forms][syntax for issue forms] and [GitHub Actions workflows]

### Claiming an issue

If you would like to work on an issue, then leave a comment containing a brief plan for resolving the issue and await feedback from the community. Your proposal shall be reviewed by at least 1 maintainer within 1 week. Participants shall agree on an *ad hoc* timeline for the work, which may be renegotiated at any point in the process.

### Getting the source code

Begin your contribution by creating a [GitHub account] or signing in and [forking this repository][fork a repo].

On your machine, configure your Git user name and email address if you haven’t already done so:

```console
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'
```

Use Git to clone your fork to your computer:

```console
git clone https://github.com/your-github-username/multiring.zig
cd multiring.zig
```

See also: [Attribution](#attribution)

### Keeping your local repository up to date

There may be new commits to this repository while you’re working on your fork. Keep your fork up to date by adding this repository as an upstream remote:

```console
git remote add upstream https://github.com/ok-ryoko/multiring.zig.git
```

When there are new changes, you can now pull them like so:

```console
git pull -r upstream main
```

`-r` is short for `--rebase`, which tells Git to apply the changes in your branch’s commits on top of the branch onto which you are rebasing (here, *main*).

### Preparing your local repository for work

Enable this repository’s commit hooks:

```console
git config --local core.hooksPath .githooks
```

Build and test the library:

```console
zig build test
```

If this step succeeds, then create a new branch for yourself:

```console
git checkout -b my-branch
```

You can now work on multiring.zig!

See also: [Commit hooks](#commit-hooks)

### Committing your changes locally

When you’re ready, run `git commit` and enter an accurate commit message.

After receiving your commit message, Git will invoke the repository’s pre-commit hook to validate changes to select types of source code. The hook must succeed in order for the commit to go through.

If you encounter an error that you don’t have time to resolve, then consider [stashing your work].

See also: [Commit messages](#commit-messages), [Commit hooks](#commit-hooks)

### Handling merge conflicts

When rebasing updates from *main* onto your branch, you’ll encounter a merge conflict when you’ve made and committed changes in your branch that are incompatible with upstream changes. You must resolve the conflict in order to complete the merge. [Ryoko] recommends the following resources for those who need to resolve a merge conflict or want to learn more:

- [git-merge documentation]
- [How do I resolve merge conflicts in my Git repository?] on Stack Overflow

We’re happy to help with merge conflicts—please [start a discussion][discussions] if you get stuck.

### Creating a pull request

Ensure that your fork on GitHub is in sync with your local repository:

```console
git push origin my-branch
```

[Create a pull request] from your branch to this repository’s *main* branch, filling out the provided [template][pull request template].

#### (Optional) Organizing your changes

Before creating a pull request, consider performing an [interactive rebase] to organize your changes into one logical set of changes per commit. This will facilitate community review of your pull request.

### Receiving feedback

Your pull request shall be reviewed by at least 1 maintainer within 2 weeks, and may be reviewed by any member of the community at any point in the process. The maintainer(s) reviewing your pull request may [ask you to make changes][incorporating feedback]. When this happens, we agree on an *ad hoc* timeline for receiving your changes on the basis of their estimated size, complexity and urgency as well as your availability.

See also: [Reviewing pull requests](#reviewing-pull-requests)

### Approval and attribution

The maintainers shall approve any pull request that satisfies the approval criteria and ensure that all work related to the pull request is attributed appropriately.

The maintainers reserve the right to rebase the commits in the pull request prior to integration.

See also: [Pull request approval criteria](#pull-request-approval-criteria), [Attribution](#attribution)

## Project practices and guidelines

### Tracking and closing issues

We use [GitHub issues] to track the following types of work:

- bug reports;
- operational chores;
- feature requests;
- suggestions to refactor, and
- suggestions to improve documentation.

We want to streamline issue creation and resolution, so we ensure that each type of issue has a corresponding [form][issue forms]. This allows issue authors to concentrate on the content (rather than the structure) of their submissions. Furthermore, submissions are more likely to contain enough relevant information to initiate and sustain a productive discussion leading to a potential incremental improvement to the project.

We don’t assign issues; all contributions are voluntarily.

We [discuss][discussions] all queries that don’t fall into one of the categories above.

#### Closure

We always provide a concise explanation for why we are closing an issue.

In general, we close an issue by opening, reviewing, approving and integrating a matching pull request.

We also close a bug report when:

- we haven’t been able to reproduce the issue, or
- we determine that the software is actually working as intended and that the issue is a result of usage error.

We also close a feature request when:

- existing features already enable the use case;
- the feature is out of the project’s scope (isn’t relevant to the target personas), or
- the cost of implementing the feature outweighs the estimated value that the feature will offer to the people using it.

We close any issue that duplicates an existing issue.

See also: [Reviewing pull requests](#reviewing-pull-requests)

### Flavors of code

- Zig source files: *src/*, *build.zig*
- [POSIX shell] scripts: *.githooks/*
- [YAML] configuration files: *.github/*

### Formatting conventions

We use a [*.gitattributes* file][.gitattributes] to enforce the following properties:

- all lines in all text files end with a line feed character (0x0A), and
- all Zig source code files are UTF-8 encoded.

We provide an [*.editorconfig* file][.editorconfig] to establish formatting conventions. [EditorConfig] is an independent specification for configuring text editors and integrated development environments to use different formatting conventions for different file types. Your text editor may already support EditorConfig; you may otherwise be able to install an extension or a plugin. We recommend but don’t require the use of EditorConfig.

We format Zig source code files using the `zig fmt` command, either manually or with a format-on-save feature/plugin in our text editor of choice. We don’t format our shell scripts or configuration files automatically, aiming only to remain consistent with existing files in the repository.

See also: [Commit hooks](#commit-hooks)

### Branching strategy

We believe that this small, simple and pre-release project should have an accordingly straightforward workflow. We therefore use a centralized workflow, collaborating directly on the *main* branch.

### Commit messages

We use a minimal and familiar commit message format:

```
<subject>

[body]

[footer(s)]
```

We always write a subject line that describes, at a high level, the effects of applying the commit. We:

- start the subject with a lowercase letter;
- use the imperative tense, and
- keep the subject shorter than 50 characters.

We write a body when we think it’s a good idea to provide supporting information (such as motivation) for the commit, wrapping at 72 characters.

We indicate each breaking change in its own footer using the following template:

```
BREAKING CHANGE: <description>
```

Ryoko recommends the following resources for those wanting to learn more about common commit practices:

- [git-commit documentation]
- [How to Write a Git Commit Message] by Chris Beams
- [Git Commit Messages: 50/72 Formatting] on Stack Overflow

We don’t plan to adopt the [Conventional Commits 1.0.0] standard because we believe, given the small scope and scale of multiring.zig, that investing in the associated teaching and tooling wouldn’t yield proportional returns and may instead raise the barrier to participation for potential contributors.

### Commit hooks

The following shell command enables this repository’s Git hooks:

```console
git config --local core.hooksPath .githooks
```

#### pre-commit

We use a [pre-commit hook] to validate our code at commit time. Here’s an example of the output:

```console
$ git commit -m 'inline switch cases on Node'
pre-commit: info: checking Zig source code formatting...
pre-commit: info: building...
pre-commit: info: running tests...
All 2 tests passed.
pre-commit: info: OK!
[main b644b00] inline switch cases on Node
 1 file changed, 5 insertions(+), 12 deletions(-)
```

When we commit a change to *build.zig* or any *.zig* file in *src/*, the pre-commit hook:

- verifies the formatting of the changed file(s);
- builds the library, and
- runs the integration test in [*multiring.zig*][source].

When we commit a change to any file in *.githooks/*, the pre-commit hook assumes it’s a shell script and lints it against the [POSIX Shell Command Language specification][POSIX shell] using ShellCheck.

When we commit a change to any *.yml* file in *.github/*, the pre-commit hook lints the file using yamllint.

If any one of the steps above fails, then the commit is aborted.

We write the pre-commit hook to perform the same steps as [our GitHub Actions workflows][workflows]. We seek to save time and hardware resources by minimizing the number of failing remote builds. Although this public repository qualifies for the free use of GitHub-hosted runners, we aim to be respectful and use only the resources that we need.

We each take responsibility for running the proper version of ShellCheck and yamllint in our local development environment. The “proper” versions are fixed to those in the [GitHub-hosted Ubuntu 22.04 LTS runner image].

See also: [Continuous integration](#continuous-integration)

### Continuous integration

We practice [continuous integration] with [GitHub Actions]. We run one workflow for each flavor of code for both pushes and pull requests to *main*. This design is appropriate because each flavor of code in this repository is consumed and validated independently.

See also: [Commit hooks](#commit-hooks)

### Reviewing pull requests

Any member of the community is welcome to participate in the review process for any pull request.

The review process has the following goals:

- Determine whether the pull request meets the approval criteria
- Ensure the absence of bugs in the pull request
- Generate a positive experience for all participants
- Share relevant insights and information
- Retain the interest of the contributor making the pull request

When changes need to be made to the pull request, our priority is to help the author succeed in making those changes.

We keep pull request reviews open for at least 5 days to account for differences in time zones and work week structure across the world. However, if the corresponding issue is urgent or blocking an urgent issue, then we may close the pull request sooner.

If a pull request appears to have stalled or been abandoned, then we follow up with the author to confirm the status of the work. If the author confirms that the pull request is abandoned or we don’t hear back within 2 weeks, then we reassign the work. We attribute any work already submitted to the original author.

See also: [Pull request approval criteria](#pull-request-approval-criteria)

### Pull request approval criteria

- The changes are all in the scope of and resolve an open issue
- The contributor has filled the [pull request template] out accurately
- The commit messages are accurate and [formatted properly](#commit-messages)

### Attribution

We identify all contributors by their preferred commit author name and email address in the [*CONTRIBUTORS* file][CONTRIBUTORS] in descending chronological order (most recent first).

### Versioning scheme

multiring.zig has no versioning scheme because we haven’t yet held a release.

### Changes to our process

These guidelines exist to foster a seamless and open contributing experience for all. We comply with them insofar as they make our work easier. When they no longer fulfill this role, we take pause to come together to discuss potential revisions openly and transparently, as we would any other issue.

[.editorconfig]: ./.editorconfig
[.gitattributes]: ./.gitattributes
[bugs]: https://github.com/ok-ryoko/multiring.zig/labels/bug
[code of conduct]: ./CODE_OF_CONDUCT.md
[continuous integration]: https://martinfowler.com/articles/continuousIntegration.html
[CONTRIBUTORS]: ./CONTRIBUTORS
[Conventional Commits 1.0.0]: https://www.conventionalcommits.org/en/v1.0.0/
[Create a pull request]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
[DEIB]: https://www.findem.ai/knowledge-center/what-is-diversity-equity-inclusion-and-belonging
[discussions]: https://github.com/ok-ryoko/multiring.zig/discussions
[documentation]: https://github.com/ok-ryoko/multiring.zig/labels/documentation
[EditorConfig]: https://editorconfig.org/
[enhancements]: https://github.com/ok-ryoko/multiring.zig/labels/enhancement
[fork a repo]: https://docs.github.com/en/github/getting-started-with-github/fork-a-repo
[Git Commit Messages: 50/72 Formatting]: https://stackoverflow.com/q/2290016
[git-commit documentation]: https://git-scm.com/docs/git-commit#_discussion
[git-merge documentation]: https://git-scm.com/docs/git-merge#_how_to_resolve_conflicts
[Git]: https://git-scm.com/
[githooks]: https://git-scm.com/docs/githooks
[GitHub account]: https://github.com/join
[GitHub Actions workflows]: https://docs.github.com/en/actions/using-workflows
[GitHub Actions]: https://github.com/features/actions
[GitHub issues]: https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues
[GitHub-hosted Ubuntu 22.04 LTS runner image]: https://github.com/actions/runner-images/blob/releases/ubuntu22/20230426/images/linux/Ubuntu2204-Readme.md
[governance]: ./GOVERNANCE.md
[How do I resolve merge conflicts in my Git repository?]: https://stackoverflow.com/q/161813
[How to Write a Git Commit Message]: https://cbea.ms/git-commit/
[incorporating feedback]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/incorporating-feedback-in-your-pull-request
[interactive rebase]: https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History
[issue forms]: ./.github/ISSUE_TEMPLATES
[issues]: https://github.com/ok-ryoko/multiring.zig/issues
[open an issue]: https://github.com/ok-ryoko/multiring.zig/issues/new/choose
[operations]: https://github.com/ok-ryoko/multiring.zig/labels/operations
[POSIX shell]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
[pre-commit hook]: ./.githooks/pre-commit
[psychological safety]: https://stackoverflow.blog/2022/01/27/psychological-safety-is-critical-for-high-performing-teams/
[pull request template]: ./.github/PULL_REQUEST_TEMPLATE.md
[Ryoko]: https://github.com/ok-ryoko
[ShellCheck]: https://www.shellcheck.net/
[source]: ./src/multiring.zig
[stashing your work]: https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning
[syntax for issue forms]: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
[use multiring.zig]: https://github.com/ok-ryoko/multiring.zig#usage
[workflows]: ./.github/workflows
[YAML]: https://yaml.org/
[yamllint]: https://yamllint.readthedocs.io/en/v1.29.0/
[Zig]: https://ziglang.org/
