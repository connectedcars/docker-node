function rewrite(token, packageJSON) {
  Object.keys(packageJSON.dependencies || []).forEach(item => {
    let dep = packageJSON.dependencies[item]
    if (dep.indexOf('@github.com') > -1) {
      packageJSON.dependencies[item] = packageJSON.dependencies[item].replace(
        'git+ssh://git',
        `git+https://${token}:`
      )
    }
  })
  return packageJSON
}
exports.rewrite = rewrite

function revert(packageJSON) {
  Object.keys(packageJSON.dependencies || []).forEach(item => {
    let dep = packageJSON.dependencies[item]
    if (dep.indexOf('@github.com') > -1) {
      packageJSON.dependencies[item] = 'git+ssh://git@' + dep.split('@')[1]
    }
  })
  return packageJSON
}
exports.revert = revert
