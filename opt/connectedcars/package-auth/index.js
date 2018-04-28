const debug = require('debug')('package-auth')
const { readFileSync, writeFileSync } = require('fs')
const { rewrite, revert } = require('./Operations')
const { rewriteLock, revertLock } = require('./OperationsLock')

if (process.argv.length === 5) {
  const command = process.argv[2]
  const token = process.argv[3]
  const filename = process.argv[4]
  try {
    const packageJSON = JSON.parse(readFileSync(filename))
    debug({
      command,
      token,
      filename,
      packageJSON
    })
    switch (command) {
      case 'rewrite':
        let rewriteOutput = rewrite(token, packageJSON)
        writeFileSync(filename, JSON.stringify(rewriteOutput, null, 2))
        break
      case 'revert':
        let revertOutput = revert(packageJSON)
        writeFileSync(filename, JSON.stringify(revertOutput, null, 2))
        break
      case 'rewrite-lock':
        let rewriteLockOutput = rewriteLock(token, packageJSON)
        writeFileSync(filename, JSON.stringify(rewriteLockOutput, null, 2))
        break
      case 'revert-lock':
        let revertLockOutput = revertLock(packageJSON)
        writeFileSync(filename, JSON.stringify(revertLockOutput, null, 2))
        break
    }
  } catch (e) {
    console.log('Something went wrong!', e.message)
    debug('Error', e)
  }
}
