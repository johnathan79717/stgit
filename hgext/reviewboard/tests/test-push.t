#require mozreviewdocker
  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

  $ cat > obs.py << EOF
  > import mercurial.obsolete
  > mercurial.obsolete._enabled = True
  > EOF

  $ cat >> client/.hg/hgrc << EOF
  > mq=
  > rebase=
  > EOF

  $ bugzilla create-bug-range TestProduct TestComponent 11
  created bugs 1 to 11

Set up the repo

  $ cd client
  $ echo 'foo' > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ echo 'anonymous head' > foo
  $ hg commit -m 'anonymous head'
  $ hg up -q -r 0
  $ echo 'with parseable id' > foo
  $ hg commit -m 'Bug 4 - Test identifier'
  created new head
  $ hg up -q -r 0
  $ hg bookmark bookmark-1
  $ echo 'bookmark-1' > foo
  $ hg commit -m 'bookmark with single commit'
  created new head
  $ hg up -q -r 0
  $ hg bookmark bookmark-2
  $ echo 'bookmark-2a' > foo
  $ hg commit -m 'bookmark with 2 commits, 1st'
  created new head
  $ echo 'bookmark-2b' > foo
  $ hg commit -m 'bookmark with 2 commits, 2nd'
  $ hg up -q -r 0
  $ hg branch test-branch
  marked working directory as branch test-branch
  (branches are permanent and global, did you want a bookmark?)
  $ echo 'branch' > foo
  $ hg commit -m 'branch with single commit'
  $ hg up -q -r 0

Seed the root changeset on the server

  $ hg push -r 0 --noreview
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  $ hg phase --public -r .

Pushing a public changeset will be quick rejected

  $ hg push -r 0 --reviewid 1
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (ignoring public changeset 3a9f6899ef84 in review request)
  abort: no non-public changesets left to review
  (add or change the -r argument to include draft changesets)
  [255]

Pushing a single changeset will initiate a single review (no children)

  $ hg push -r 1 --reviewid 1 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (adding commit id to 1 changesets)
  saved backup bundle to $TESTTMP/client/.hg/strip-backup/6f06b4ac6efe*-addcommitid.hg (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  6:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

{reviews} template works

  $ hg log -r 0::6b33f0dbef02 --template "{node|short} {reviews % '{get(review, \"url\")} {get(review, \"status\")}'}\n"
  3a9f6899ef84 
  6b33f0dbef02 http://$DOCKER_HOSTNAME:$HGPORT1/r/2 pending

Pushing no changesets will do a re-review

  $ hg push -r 6b33f0dbef02 --reviewid 1 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  6:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Pushing no changesets will do a re-review but will not reset a published
review back to draft (See bugs 1096761 and 1179552).
TODO the behavior here is not correct: a new parent draft should not be
created if all the review requests didn't change

  $ rbmanage publish 1
  $ hg push -r 6b33f0dbef02 --reviewid 1 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  6:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Pushing patches from mq will result in a warning

  $ echo 'mq patch' > foo
  $ hg qnew -m 'mq patch' -d '0 0' patch1
  $ hg push -r . --reviewid 2 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  (You are using mq to develop patches. *) (glob)
  submitting 1 changesets for review
  
  changeset:  7:cccd43f18cec
  summary:    mq patch
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/4 (draft)
  
  review id:  bz://2/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/3 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

  $ hg qpop
  popping patch1
  patch queue now empty

Custom identifier will create a new review from same changesets.

  $ hg push -r 6b33f0dbef02 --reviewid 3 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  6:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/6 (draft)
  
  review id:  bz://3/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/5 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

SSH works
(This test is now redundant. But removing it completely will impact the
rest of the test.)

  $ hg push -r 1 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (adding commit id to 1 changesets)
  saved backup bundle to $TESTTMP/client/.hg/strip-backup/6a5e03035256*-addcommitid.hg (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  6:62eca46e88fb
  summary:    Bug 4 - Test identifier
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/8 (draft)
  
  review id:  bz://4/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/7 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Specifying multiple -r for the same head works

  $ hg push -r 0 -r 6b33f0dbef02 --reviewid 5 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  5:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/10 (draft)
  
  review id:  bz://5/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/9 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Specifying a revision range works

  $ hg push -r 0::6b33f0dbef02 --reviewid 6 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  5:6b33f0dbef02
  summary:    anonymous head
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/12 (draft)
  
  review id:  bz://6/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/11 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Prepare for multi changeset tests

  $ hg up -q -r 0
  $ echo ignore > foo
  $ hg -q commit -m 'Ignore this commit'
  $ echo base > foo
  $ hg commit -m 'Review base'
  $ echo middle > foo
  $ hg commit -m 'Middle commit'
  $ echo tip > foo
  $ hg commit -m 'Review tip'
  $ echo beyond > foo
  $ hg commit -m 'Beyond review tip'
  $ hg -q up -r .^
  $ echo newhead > foo
  $ hg commit -m 'Unrelated head'
  created new head
  $ hg -q up -r 946b2ccfbcc1

A dirty working copy of a reviewed node will abort because of potential rewriting

  $ echo dirty > foo
  $ hg push -r 8::10 --reviewid 7
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  abort: uncommitted changes
  [255]

A dirty working copy of a child of a review node will abort

  $ hg push -r 8::9 --reviewid 7
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  abort: uncommitted changes
  [255]

  $ hg revert -C foo

Specifying a base revision limits reviewed changesets

  $ hg push -r 8::10 --reviewid 7 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 4 changesets with 4 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 3 changesets for review
  
  changeset:  8:29cc7959baba
  summary:    Review base
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/14 (draft)
  
  changeset:  9:6d5a65ca7a91
  summary:    Middle commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/15 (draft)
  
  changeset:  10:946b2ccfbcc1
  summary:    Review tip
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/16 (draft)
  
  review id:  bz://7/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/13 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Specifying multiple -r arguments selects base and tip

  $ hg push -r 8 -r 10 --reviewid 8 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 3 changesets for review
  
  changeset:  8:29cc7959baba
  summary:    Review base
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/18 (draft)
  
  changeset:  9:6d5a65ca7a91
  summary:    Middle commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/19 (draft)
  
  changeset:  10:946b2ccfbcc1
  summary:    Review tip
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/20 (draft)
  
  review id:  bz://8/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/17 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Specifying multiple -r in reverse order still works

  $ hg push -r 10 -r 8 --reviewid 9 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 3 changesets for review
  
  changeset:  8:29cc7959baba
  summary:    Review base
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/22 (draft)
  
  changeset:  9:6d5a65ca7a91
  summary:    Middle commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/23 (draft)
  
  changeset:  10:946b2ccfbcc1
  summary:    Review tip
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/24 (draft)
  
  review id:  bz://9/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/21 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

-r and -c are mutually exclusive

  $ hg push -c 8 -r 9
  abort: cannot specify both -r and -c
  [255]

-c can be used to select a single changeset to review

  $ hg push -c 9 --reviewid 11 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  9:6d5a65ca7a91
  summary:    Middle commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/26 (draft)
  
  review id:  bz://11/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/25 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

Reviewing merge commits is rejected

  $ hg up -q -r 0
  $ echo merge1 > foo
  $ hg commit -m 'Bug 1 - Merge A'
  created new head
  $ hg up -q -r 0
  $ echo merge2 > foo
  $ hg commit -m 'Bug 1 - Merge B'
  created new head
  $ hg merge --tool internal:other 47aed783df21
  0 files updated, 1 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m 'Bug 1 - Do merge'

  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 3 changesets with 3 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 3 changesets for review
  abort: cannot review merge commits (abd430935a8b)
  [255]

We disallow completely empty revisions.

  $ hg up -q -r 0
  $ hg qnew -m 'mq patch' -d '0 0' empty-patch
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  abort: cannot review empty changeset e3b1b495a7d2
  (add files to or remove changeset)
  [255]

Check for empty commits not at the tip

  $ echo after-empty > foo
  $ hg qnew -m 'Bug 1 - after empty' -d '0 0' after-empty
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  abort: cannot review empty changeset e3b1b495a7d2
  (add files to or remove changeset)
  [255]

  $ hg qpop -a
  popping after-empty
  popping empty-patch
  patch queue now empty

You can choose to publish automatically without a prompt

  $ hg push -r 6b33f0dbef02 --reviewid 1 --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  5:6b33f0dbef02
  summary:    anonymous head
  review:     http://*:$HGPORT1/r/2 (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (published review request 1)
  [1]

Cleanup

  $ mozreview stop
  stopped 9 containers
