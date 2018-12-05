const providers = {
    github: 'github.com'
}

const providerRegex = new RegExp(
    `^(?<provider>${Object.keys(providers).join('|')}):(?<username>.*)/(?<repository>[^#]*)(?<version>#.+)?$`
  )

function packageJSONRewrite(packageJSON, token) {
    let changed = false
    for(let dependencyType of ['dependencies', 'devDependencies', 'peerDependencies', 'bundledDependencies', 'optionalDependencies']) {
        if(packageJSON[dependencyType] == null) {
            continue
        }
        for (let dependencyName of Object.keys(packageJSON[dependencyType]) ) {
            let dependencyUrl = packageJSON[dependencyType][dependencyName]
            let replacement = replaceUrl(dependencyUrl, token)
            if(replacement !== dependencyUrl) {
                packageJSON[dependencyType][dependencyName] = replacement
                changed = true
            }
        }
    }
    return changed
}

function packageLockJSONRewrite(packageLockJSON, token) {
    let changed = false
    for(let dependencyType of ['dependencies', 'devDependencies', 'peerDependencies', 'bundledDependencies', 'optionalDependencies']) {
        if(packageLockJSON[dependencyType] == null) {
            continue
        }
        for (let dependencyName of Object.keys(packageLockJSON[dependencyType])) {
            let dependencyUrl = packageLockJSON[dependencyType][dependencyName].version
            let replacement = replaceUrl(dependencyUrl, token)
            if (replacement !== dependencyUrl) {
                packageLockJSON[dependencyType][dependencyName].version = replacement
                changed = true
            }
        }
    }
    return changed
}

function replaceUrl(url, token) {
    let match = url.match(providerRegex)
    if(match) {
        const { provider, username, repository, version } = { ...match.groups }
        const host = providers[provider]
        return `git+https://${token}:@${host}/${username}/${repository}.git${version || ''}`
    }
    return url.replace(/^git\+ssh:\/\/git(@github.com)/, `git+https://${token}:$1`)
}

module.exports = { packageJSONRewrite, packageLockJSONRewrite }