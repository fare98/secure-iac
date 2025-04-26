multibranchPipelineJob('secure-idp') {
  branchSources {
    git {
      remote('<YOUR_GIT_REPO>')
      credentialsId('git-ssh-key')
    }
  }
  orphanedItemStrategy {
    discardOldItems { numToKeep(10) }
  }
}
