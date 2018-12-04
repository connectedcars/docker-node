#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const { spawn } = require('child_process')

const { packageJSONRewrite, packageLockJSONRewrite } = require('./package-json-rewrite')

let githubPatToken = process.env['GITHUB_PAT']

let processName = path.basename(process.argv[1])
let processArgs = process.argv.slice(2)

if(process.argv[1] === __filename) {
    console.error("Need to symlink this file")
    process.exit(255)
}

if (githubPatToken && fs.existsSync('package.json') && !fs.existsSync('package.json.orig') && !fs.existsSync('package-lock.json.orig')) {
    try {
        console.log("Rewrite github git+ssh references and inject personal access token")
        const packageJSON = JSON.parse(fs.readFileSync('package.json'))
        if (packageJSONRewrite(packageJSON, githubPatToken)) {
            replace('package.json', JSON.stringify(packageJSON, null, 2))
        }
        if (fs.existsSync('package-lock.json')) {
            const packageLockJSON = JSON.parse(fs.readFileSync('package-lock.json'))
            if (packageLockJSONRewrite(packageLockJSON, githubPatToken)) {
                replace('package-lock.json', JSON.stringify(packageLockJSON, null, 2))
            }
        }

        runProcess(`/usr/local/bin/${processName}`, processArgs).then(res => {
            console.log(`npm exit code: ${res.code}, signal: ${res.signal}`)
            restore()
            process.exit(res.code)
        })
    } catch (e) {
        console.error(e)
        restore()
        process.exit(255)
    }
} else {
    runProcess(`/usr/local/bin/${processName}`, processArgs).then(res => {
        console.log(`npm exit code: ${res.code}, signal: ${res.signal}`)
        restore()
        process.exit(res.code)
    })
}

function runProcess(path, processArgs) {
    const cmd = spawn(path, processArgs, { stdio: "inherit" })
    return new Promise(resolve => {
        cmd.on('exit', (code, signal) => {
            resolve({ code, signal })
        })
    })
}

function replace(filename, data) {
    fs.writeFileSync(`${filename}.new`, data)
    fs.renameSync(filename, `${filename}.orig`)
    fs.renameSync(`${filename}.new`, `${filename}`)
}

function restore() {
    try {
        fs.renameSync('package.json.orig', 'package.json')
    } catch (e) {
        // Don't care if it fail's
    }
    try {
        fs.renameSync('package-lock.json.orig', 'package-lock.json')
    } catch (e) {
        // Don't care if it fail's
    }
}