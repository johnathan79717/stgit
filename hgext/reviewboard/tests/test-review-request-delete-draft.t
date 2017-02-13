#require mozreviewdocker

  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

  $ mozreview create-user submitter@example.com password 'Dummy Submitter' --username submitter --uid 2001 --scm-level 1
  Created user 6
  $ submitterkey=`mozreview create-api-key submitter@example.com`
  $ exportbzauth submitter@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'Initial Bug'

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ hg phase --public -r .

  $ echo foo1 > foo
  $ hg commit -m 'Bug 1 - Initial commit'
  $ hg --config bugzilla.username=submitter@example.com --config bugzilla.apikey=${submitterkey} --config reviewboard.autopublish=false push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  (adding commit id to 1 changesets)
  saved backup bundle to $TESTTMP/client/.hg/strip-backup/8c2be86a13c9*-addcommitid.hg (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  1:65e5c536f9cc
  summary:    Bug 1 - Initial commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

Now publish the review and create a new draft

  $ rbmanage publish 1
  $ echo foo3 > foo
  $ hg commit --amend > /dev/null
  $ hg --config bugzilla.username=submitter@example.com --config bugzilla.apikey=${submitterkey} --config reviewboard.autopublish=false push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT6/test-repo
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  1:2c68bc327689
  summary:    Bug 1 - Initial commit
  review:     http://$DOCKER_HOSTNAME:$HGPORT1/r/2 (draft)
  
  review id:  bz://1/mynick
  review url: http://$DOCKER_HOSTNAME:$HGPORT1/r/1 (draft)
  
  (review requests lack reviewers; visit review url to assign reviewers)
  (visit review url to publish these review requests so others can see them)

We should have a disagreement between published and draft

  $ rbmanage dumpreview 1
  id: 1
  status: pending
  public: true
  bugs:
  - '1'
  commit: bz://1/mynick
  submitter: submitter+6
  summary: bz://1/mynick
  description: This is the parent review request
  target_people: []
  extra_data:
    calculated_trophies: true
    p2rb.reviewer_map: '{}'
  commit_extra_data:
    p2rb: true
    p2rb.base_commit: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.commits: '[["65e5c536f9cc5816ef28ebaff6a0db47b9af0fee", 2]]'
    p2rb.discard_on_publish_rids: '[]'
    p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.identifier: bz://1/mynick
    p2rb.is_squashed: true
    p2rb.unpublished_rids: '[]'
  diffs:
  - id: 1
    revision: 1
    base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
    name: diff
    extra: {}
    patch:
    - diff --git a/foo b/foo
    - '--- a/foo'
    - +++ b/foo
    - '@@ -1,1 +1,1 @@'
    - -foo
    - +foo1
    - ''
  approved: false
  approval_failure: Commit 65e5c536f9cc5816ef28ebaff6a0db47b9af0fee is not approved.
  draft:
    bugs:
    - '1'
    commit: bz://1/mynick
    summary: bz://1/mynick
    description: This is the parent review request
    target_people: []
    extra:
      calculated_trophies: true
      p2rb.reviewer_map: '{"2": []}'
    commit_extra_data:
      p2rb: true
      p2rb.base_commit: 3a9f6899ef84c99841f546030b036d0124a863cf
      p2rb.commits: '[["2c68bc327689343c967bcb80b9a3fd8d9bc50eb4", 2]]'
      p2rb.discard_on_publish_rids: '[]'
      p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
      p2rb.identifier: bz://1/mynick
      p2rb.is_squashed: true
      p2rb.unpublished_rids: '[]'
    diffs:
    - id: 3
      revision: 2
      base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
      name: diff
      extra: {}
      patch:
      - diff --git a/foo b/foo
      - '--- a/foo'
      - +++ b/foo
      - '@@ -1,1 +1,1 @@'
      - -foo
      - +foo3
      - ''

  $ rbmanage dumpreview 2
  id: 2
  status: pending
  public: true
  bugs:
  - '1'
  commit: null
  submitter: submitter+6
  summary: Bug 1 - Initial commit
  description:
  - Bug 1 - Initial commit
  - ''
  - 'MozReview-Commit-ID: 124Bxg'
  target_people: []
  extra_data:
    calculated_trophies: true
  commit_extra_data:
    p2rb: true
    p2rb.author: test
    p2rb.commit_id: 65e5c536f9cc5816ef28ebaff6a0db47b9af0fee
    p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.identifier: bz://1/mynick
    p2rb.is_squashed: false
  diffs:
  - id: 2
    revision: 1
    base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
    name: diff
    extra: {}
    patch:
    - diff --git a/foo b/foo
    - '--- a/foo'
    - +++ b/foo
    - '@@ -1,1 +1,1 @@'
    - -foo
    - +foo1
    - ''
  approved: false
  approval_failure: A suitable reviewer has not given a "Ship It!"
  draft:
    bugs:
    - '1'
    commit: null
    summary: Bug 1 - Initial commit
    description:
    - Bug 1 - Initial commit
    - ''
    - 'MozReview-Commit-ID: 124Bxg'
    target_people: []
    extra:
      calculated_trophies: true
    commit_extra_data:
      p2rb: true
      p2rb.author: test
      p2rb.commit_id: 2c68bc327689343c967bcb80b9a3fd8d9bc50eb4
      p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
      p2rb.identifier: bz://1/mynick
      p2rb.is_squashed: false
    diffs:
    - id: 4
      revision: 2
      base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
      name: diff
      extra: {}
      patch:
      - diff --git a/foo b/foo
      - '--- a/foo'
      - +++ b/foo
      - '@@ -1,1 +1,1 @@'
      - -foo
      - +foo3
      - ''

Discarding the parent review request draft should discard draft on children

  $ rbmanage discard-review-request-draft 1
  Discarded draft for review request 1

  $ rbmanage dumpreview 1
  id: 1
  status: pending
  public: true
  bugs:
  - '1'
  commit: bz://1/mynick
  submitter: submitter+6
  summary: bz://1/mynick
  description: This is the parent review request
  target_people: []
  extra_data:
    calculated_trophies: true
    p2rb.reviewer_map: '{}'
  commit_extra_data:
    p2rb: true
    p2rb.base_commit: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.commits: '[["65e5c536f9cc5816ef28ebaff6a0db47b9af0fee", 2]]'
    p2rb.discard_on_publish_rids: '[]'
    p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.identifier: bz://1/mynick
    p2rb.is_squashed: true
    p2rb.unpublished_rids: '[]'
  diffs:
  - id: 1
    revision: 1
    base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
    name: diff
    extra: {}
    patch:
    - diff --git a/foo b/foo
    - '--- a/foo'
    - +++ b/foo
    - '@@ -1,1 +1,1 @@'
    - -foo
    - +foo1
    - ''
  approved: false
  approval_failure: Commit 65e5c536f9cc5816ef28ebaff6a0db47b9af0fee is not approved.

  $ rbmanage dumpreview 2
  id: 2
  status: pending
  public: true
  bugs:
  - '1'
  commit: null
  submitter: submitter+6
  summary: Bug 1 - Initial commit
  description:
  - Bug 1 - Initial commit
  - ''
  - 'MozReview-Commit-ID: 124Bxg'
  target_people: []
  extra_data:
    calculated_trophies: true
  commit_extra_data:
    p2rb: true
    p2rb.author: test
    p2rb.commit_id: 65e5c536f9cc5816ef28ebaff6a0db47b9af0fee
    p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.identifier: bz://1/mynick
    p2rb.is_squashed: false
  diffs:
  - id: 2
    revision: 1
    base_commit_id: 3a9f6899ef84c99841f546030b036d0124a863cf
    name: diff
    extra: {}
    patch:
    - diff --git a/foo b/foo
    - '--- a/foo'
    - +++ b/foo
    - '@@ -1,1 +1,1 @@'
    - -foo
    - +foo1
    - ''
  approved: false
  approval_failure: A suitable reviewer has not given a "Ship It!"

Cleanup

  $ mozreview stop
  stopped 9 containers
