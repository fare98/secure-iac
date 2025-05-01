multibranchPipelineJob('secure-idp') {
  branchSources {
    git {
      remote('git@github.com:fare98/secure-iac.git')
      credentialsId('git-ssh-key')
    }
  }
  orphanedItemStrategy {
    discardOldItems { numToKeep(10) }
  }
}
