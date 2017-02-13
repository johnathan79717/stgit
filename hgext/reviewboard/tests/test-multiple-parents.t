#require mozreviewdocker
  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

  $ bugzilla create-bug-range TestProduct TestComponent 2
  created bugs 1 to 2

Set up repo

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ echo foo2 > foo
  $ hg commit -m 'second commit'

  $ hg phase --public -r 0

Do the initial review

  $ hg push -r 1 --reviewid 1 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (adding commit id to 1 changesets)
  saved backup bundle to $TESTTMP/client/.hg/strip-backup/cd3395bd3f8a*-addcommitid.hg (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  1:d5b7a3621249
  summary:    second commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Pushing with a different review ID will create a "duplicate" review

  $ hg push -r 1 --reviewid 2 --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  1:d5b7a3621249
  summary:    second commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/4 (draft)
  
  review id:  bz://2/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/3 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)
  [1]

  $ cat .hg/reviews
  u http://$DOCKER_HOSTNAME:$HGPORT1
  r ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  p bz://1/mynick 1
  p bz://2/mynick 3
  c d5b7a3621249b0f1973c0daf64248a4b77fe52e8 2
  c d5b7a3621249b0f1973c0daf64248a4b77fe52e8 4
  pc d5b7a3621249b0f1973c0daf64248a4b77fe52e8 1
  pc d5b7a3621249b0f1973c0daf64248a4b77fe52e8 3

  $ hg log --template "{reviews % '{get(review, \"url\")}\n'}"
  http://$DOCKER_HOSTNAME:$HGPORT1/r/2
  http://$DOCKER_HOSTNAME:$HGPORT1/r/4

Cleanup

  $ mozreview stop
  stopped 9 containers
