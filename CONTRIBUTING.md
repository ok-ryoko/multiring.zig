# Contributing to multiring.zig

Thank you for your interest in improving this project! We welcome contributions of all types and sizes from everyone.

## Code of conduct

The community around this project has a [code of conduct] that all participants are expected to understand and follow. We believe that enforcing a code of conduct is crucial for cultivating [diversity, equity, inclusion and belonging][DEIB] as well as [psychological safety]. These are key ingredients for creating a healthy and self-sustaining community that develops excellent software and generates fulfilling experiences.

## Table of contents

- [Code of conduct](#code-of-conduct)
- [Ways to contribute](#ways-to-contribute)
- [Development requirements](#development-requirements)
- [Guidelines](#guidelines)
  - [Flavors of code](#flavors-of-code)
  - [Formatting conventions](#formatting-conventions)
  - [Commit messages](#commit-messages)
  - [Commit hooks](#commit-hooks)
  - [Branching strategy](#branching-strategy)
  - [Continuous integration](#continuous-integration)
  - [Issues and labels](#issues-and-labels)
  - [Versioning scheme](#versioning-scheme)
  - [Attribution](#attribution)
  - [Changes to our process](#changes-to-our-process)

## Ways to contribute

- [🐛 Report a bug or reproduce an existing bug][bugs]
- [🎁 Suggest a feature][enhancements]
- [🔩 Suggest a refactor][enhancements]
- [📚 Suggest improvements to documentation][documentation]
- [🏷️ Comment or work on an issue][issues]
- [💬 Start a discussion][discussions]
- [🕹️ Use multiring.zig][use multiring.zig] or write about it

## Development requirements

To work on multiring.zig, you’ll need some or all of following software:

- [Git] 2.9
- [Zig] 0.9.1, for work on the multiring data structure
- [ShellCheck] 0.8, for [Git hook][githooks] development
- [yamllint] 1.28, for [GitHub issue forms][syntax for issue forms] and [GitHub Actions workflows]

## Guidelines

### Flavors of code

- Zig source files: *src/*, *build.zig*
- [POSIX shell] scripts: *.githooks/*
- [YAML] configuration files: *.github/*

### Formatting conventions

We use a [*.gitattributes*][.gitattributes] file to enforce the following properties:

- all lines in all text files end with a line feed character (0x0A), and
- all Zig source code files are UTF-8 encoded.

We provide an [*.editorconfig*][.editorconfig] file to establish formatting conventions for different types of source code. [EditorConfig] is an independent specification for configuring text editors and integrated development environments to use different formatting conventions for different file types. Your text editor may already support EditorConfig; you may otherwise be able to install an extension or a plugin.

We format Zig source code files using the `zig fmt` command, either manually or with a format-on-save feature/plugin in our text editor of choice. We don’t format our shell scripts or configuration files automatically, aiming only to remain consistent with existing files in the repository.

See also: [pre-commit](#pre-commit)

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

We write a body when we think it’s a good idea to provide supporting information for the commit, wrapping at 72 characters.

We indicate each breaking change in its own footer using the following template:

```
BREAKING CHANGE: <description>
```

[Ryoko] recommends the following resources for those wanting to learn more about common commit practices:

- [git-commit Documentation]
- [How to Write a Git Commit Message] by Chris Beams
- [Git Commit Messages: 50/72 Formatting] on Stack Overflow

We don’t plan to adopt the [Conventional Commits 1.0.0] standard because we believe, given the small scope and scale of multiring.zig, that investing in the associated teaching and tooling wouldn’t yield proportional returns and may instead raise the barrier to participation for potential contributors.

### Commit hooks

Run the following command in the repository root to enable our commit hooks:

```console
git config --local core.hooksPath .githooks
```

#### pre-commit

We use a [pre-commit hook] to validate our code at commit time.

When we commit a change to *build.zig* or any *.zig* file in *src/*, the pre-commit hook:

- verifies the formatting of the changed file(s);
- builds the library, and
- runs the integration test in [*multiring.zig*][source].

When we commit a change to any file in *.githooks/*, the pre-commit hook assumes it’s a shell script and lints it against the [POSIX Shell Command Language specification][POSIX shell] using ShellCheck.

When we commit a change to any *.yml* file in *.github/*, the pre-commit hook lints the file using yamllint.

If any one of the steps above fails, then the commit is aborted.

We write the pre-commit hook to perform the same steps as our GitHub Actions [workflows]. We seek to save time and hardware resources by minimizing the number of failing remote builds. Although this public repository qualifies for the free use of GitHub-hosted runners, we aim to be respectful and use only the resources that we need.

We each take responsibility for running the proper version of ShellCheck and yamllint in our local development environment. The “proper” versions are fixed to those in the [GitHub-hosted Ubuntu 22.04 LTS runner image].

See also: [Continuous integration](#continuous-integration)

### Branching strategy

We believe that this small, simple and pre-release project should have an accordingly straightforward workflow. We therefore use a centralized workflow, collaborating directly on the *main* branch.

### Continuous integration

We practice [continuous integration] (CI) with [GitHub Actions]. We run one workflow for each flavor of code for both pushes and pull requests to *main*. This design is appropriate because each flavor of code in this repository is consumed and validated independently.

See also: [pre-commit](#pre-commit)

### Issues

We use [GitHub issues][issues] to track the following types of work:

- bug reports;
- feature requests;
- suggestions to refactor, and
- suggestions to improve documentation.

We want to streamline issue creation and resolution, so we ensure that each type of issue has a corresponding [form][issue forms]. This allows issue authors to concentrate on the content (rather than the structure) of their submissions. Furthermore, submissions are more likely to contain enough relevant information to initiate and sustain a productive discussion leading to a potential resolution of the issue.

We don’t assign issues; all contributions are voluntarily. When we want to work on an issue, we leave a comment containing our plan for resolving the issue.

We [discuss][discussions] all other queries that don’t fall into one of the categories above.

### Versioning scheme

multiring.zig has no versioning scheme because we haven’t yet held a release.

### Attribution

All contributors are identified by their preferred commit author name and email address in the [`CONTRIBUTORS`][CONTRIBUTORS] file in descending chronological order (most recent first).

Persons who have contributed substantially to multiring.zig are identified by their preferred commit author name and email address in the [`AUTHORS`][AUTHORS] file in ascending chronological order (most recent last).

### Changes to our process

These guidelines exist to foster a seamless and open contributing experience for all. We comply with them insofar as they make our work easier. When they no longer fulfill this role, we take pause to come together to discuss pain points and potential revisions openly and transparently.

[.editorconfig]: ./.editorconfig
[.gitattributes]: ./.gitattributes
[AUTHORS]: ./AUTHORS
[bugs]: https://github.com/ok-ryoko/multiring.zig/labels/bug
[code of conduct]: ./CODE_OF_CONDUCT.md
[continuous integration]: https://martinfowler.com/articles/continuousIntegration.html
[Contributor Covenant]: https://www.contributor-covenant.org/
[CONTRIBUTORS]: ./CONTRIBUTORS
[Conventional Commits 1.0.0]: https://www.conventionalcommits.org/en/v1.0.0/
[DEIB]: https://www.findem.ai/knowledge-center/what-is-diversity-equity-inclusion-and-belonging
[discussions]: https://github.com/ok-ryoko/multiring.zig/discussions
[documentation]: https://github.com/ok-ryoko/multiring.zig/labels/documentation
[EditorConfig]: https://editorconfig.org/
[enhancements]: https://github.com/ok-ryoko/multiring.zig/labels/enhancement
[Git Commit Messages: 50/72 Formatting]: https://stackoverflow.com/q/2290016
[git-commit Documentation]: https://git-scm.com/docs/git-commit#_discussion
[Git]: https://git-scm.com/
[githooks]: https://git-scm.com/docs/githooks
[GitHub Actions workflows]: https://docs.github.com/en/actions/using-workflows
[GitHub Actions]: https://github.com/features/actions
[GitHub-hosted Ubuntu 22.04 LTS runner image]: https://github.com/actions/runner-images/blob/ubuntu22/20221212.1/images/linux/Ubuntu2204-Readme.md
[How to Write a Git Commit Message]: https://cbea.ms/git-commit/
[issue forms]: ./.github/ISSUE_TEMPLATES
[issues]: https://github.com/ok-ryoko/multiring.zig/issues
[POSIX shell]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
[pre-commit hook]: ./.githooks/pre-commit
[psychological safety]: https://stackoverflow.blog/2022/01/27/psychological-safety-is-critical-for-high-performing-teams/
[Ryoko]: https://github.com/ok-ryoko
[ShellCheck]: https://www.shellcheck.net/
[source]: ./src/multiring.zig
[syntax for issue forms]: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
[use multiring.zig]: https://github.com/ok-ryoko/multiring.zig#usage
[workflows]: ./.github/workflows
[YAML]: https://yaml.org/
[yamllint]: https://yamllint.readthedocs.io/en/v1.28.0/
[Zig]: https://ziglang.org/
