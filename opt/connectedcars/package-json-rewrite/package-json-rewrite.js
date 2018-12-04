const githubRegex = /^git\+ssh:\/\/git(@github.com)/

function packageJSONRewrite(packageJSON, token) {
    let changed = false
    for(let dependencyType of ['dependencies', 'devDependencies', 'peerDependencies', 'bundledDependencies', 'optionalDependencies']) {
        if(packageJSON[dependencyType] == null) {
            continue
        }
        for (let dependencyName of Object.keys(packageJSON[dependencyType]) ) {
            let dependencyUrl = packageJSON[dependencyType][dependencyName]
            let replacement = dependencyUrl.replace(githubRegex, `git+https://${token}:$1`)
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
        for (let dependencyName of Object.keys(packageLockJSON[dependencyType]) || []) {
            let dependencyUrl = packageLockJSON[dependencyType][dependencyName].version
            let replacement = dependencyUrl.replace(githubRegex, `git+https://${token}:$1`)
            if (replacement !== dependencyUrl) {
                packageLockJSON[dependencyType][dependencyName].version = replacement
                changed = true
            }
        }
    }
    return changed
}
module.exports = { packageJSONRewrite, packageLockJSONRewrite }