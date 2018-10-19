const providers = {
  github: 'github.com',
}

const providerNames = Object.keys(providers).join('|')

const providerRegex = new RegExp(
  `^(?<provider>${providerNames}):(?<username>.*)/(?<repository>[^#]*)(?<version>#.+)$`
)

function rewrite(token, packageJSON) {
  Object.keys(packageJSON.dependencies || []).forEach(item => {
    let dep = packageJSON.dependencies[item]
    if (dep.indexOf('@github.com') > -1) {
      packageJSON.dependencies[item] = packageJSON.dependencies[item].replace(
        'git+ssh://git',
        `git+https://${token}:`
      )
    }
    if (providerRegex.test(dep)) {
      const { provider, username, repository, version } = dep.match(
        providerRegex
      ).groups
      const host = providers[provider]
      packageJSON.dependencies[
        item
      ] = `git+https://${token}:@${host}/${username}/${repository}.git${version}`
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
