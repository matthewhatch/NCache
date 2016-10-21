# Contributing

## Commit Messages

Use the following format for commit messages, from
[Tim Pope's excellent writeup](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html):

```
Capitalized, short (50 chars or less) summary

More detailed explanatory text, if necessary.  Wrap it to about 72
characters or so.  In some contexts, the first line is treated as the
subject of an email and the rest of the text as the body.  The blank
line separating the summary from the body is critical (unless you omit
the body entirely); tools like rebase can get confused if you run the
two together.

Write your commit message in the imperative: "Fix bug" and not "Fixed bug"
or "Fixes bug."  This convention matches up with commit messages generated
by commands like git merge and git revert.

Further paragraphs come after blank lines.

- Bullet points are okay, too

- Use a hanging indent

- Typically a hyphen or asterisk is used for the bullet, followed by a
  single space, with blank lines in between, but conventions vary here
```

For rationality behind these rules, see the writeup above.

## Rebase vs. Merge

**DO**
```bash
$ git fetch
$ git rebase origin/master
```

**DON'T**
```bash
$ git fetch
$ git merge origin/master
```

---

Put your work on top of the remote `master` branch (via `git rebase origin/master`) in order to keep
your feature branch up-to-date. Never merge the remote `master` branch on top of your work (via `git
merge origin/master`). The only time a merge should be used is when that feature branch is merged
into master. Never the other way around.

> A git merge should only be used for incorporating the entire feature set of a branch into another
> one, in order to preserve a useful, semantically correct history graph. Such a clean graph has
> significant added value. All other use cases are better off using rebase.

— [Getting solid at Git rebase vs. merge](https://medium.com/@porteneuve/getting-solid-at-git-rebase-vs-merge-4fa1a48c53aa)

---

## Atomic Commits

Atomic means that the given commit is as small as possible while

1. still delivering some tangible value, and
2. not introducing any bugs, regressions, or test failures.

## Unidirectional Commits

Unidirectional commits progress the codebase consistently forward chronologically. If you find that
you introduce some new code in one commit only to change or remove it later, your commits may not be
unidirectional.

Committing consistently and then rearranging and squashing your commit history is the easiest way to
keep commits clean, atomic, and unidirectional.

Atomic and unidirectional commits allow for bisecting, which is often the fastest way to find and
fix regressions and potentially catostrophic or time-sensitive bugs.
