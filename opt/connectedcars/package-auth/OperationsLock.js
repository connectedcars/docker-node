function rewriteLock(token, packageJSON) {
  Object.keys(packageJSON.dependencies || []).forEach(item => {
    let dep = packageJSON.dependencies[item].version
    if (dep.indexOf('@github.com') > -1) {
      packageJSON.dependencies[item].version = packageJSON.dependencies[
        item
      ].version.replace('git+ssh://git', `git+https://${token}:`)
    }
  })
  return packageJSON
}
exports.rewriteLock = rewriteLock

function revertLock(packageJSON) {
  Object.keys(packageJSON.dependencies || []).forEach(item => {
    let dep = packageJSON.dependencies[item].version
    if (dep.indexOf('@github.com') > -1) {
      packageJSON.dependencies[item].version =
        'git+ssh://git@' + dep.split('@')[1]
    }
  })
  return packageJSON
}
exports.revertLock = revertLock
