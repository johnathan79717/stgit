#require mozreviewdocker
  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

  $ bugzilla create-bug TestProduct TestComponent summary

  $ cat > obs.py << EOF
  > import mercurial.obsolete
  > mercurial.obsolete._enabled = True
  > EOF
  $ echo "obs=$TESTTMP/obs.py" >> client/.hg/hgrc

  $ cd client
  $ echo 'foo' > foo0
  $ hg commit -A -m 'root commit'
  adding foo0
  $ hg push --noreview
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  $ hg phase --public -r .

  $ echo 'foo1' > foo1
  $ hg commit -A -m 'Bug 1 - Foo 1'
  adding foo1
  $ hg push --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (adding commit id to 1 changesets)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  2:0b3e14fe3ff1
  summary:    Bug 1 - Foo 1
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Splitting the changeset results in multiple reviews

  $ hg up -r 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo 'foo2' > foo2
  $ hg commit -A -m 'Bug 1 - Foo 2'
  adding foo2
  created new head
  $ echo 'foo3' > foo3
  $ hg commit -A -m 'Bug 1 - Foo 3'
  adding foo3
  $ hg debugobsolete -d '0 0' 0b3e14fe3ff19019110705e72dcf563c0ef551f6 8cfe623ffa827c2382e41f8cd479005984c94e76 02a9514408b763f7534d4f250046b513799ffe4c

  $ rbmanage publish 1
  $ hg push --config reviewboard.autopublish=false
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files (+1 heads)
  remote: recorded push in pushlog
  submitting 2 changesets for review
  
  changeset:  3:8cfe623ffa82
  summary:    Bug 1 - Foo 2
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  changeset:  4:02a9514408b7
  summary:    Bug 1 - Foo 3
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/3 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Cleanup

  $ mozreview stop
  stopped 9 containers
