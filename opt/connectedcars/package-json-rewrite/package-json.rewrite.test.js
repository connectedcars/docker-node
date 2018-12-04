const { packageJSONRewrite, packageLockJSONRewrite } = require('./package-json-rewrite')

test('replace all git+ssh with https', () => {
    let packageJSON = {
        dependencies: {
            'awesome-module': 'git+ssh://git@github.com/connectedcars/awesome-module.git'
        }
    }
    packageJSONRewrite(packageJSON, 'ACCESSTOKENHERE')
    expect(packageJSON).toEqual({
        dependencies: {
            'awesome-module':
                'git+https://ACCESSTOKENHERE:@github.com/connectedcars/awesome-module.git'
        }
    })
})

test('replace all github: with https', () => {
    let packageJSON = {
        dependencies: {
            "@connectedcars/some-project": "github:connectedcars/some-project",
        }
    }
    packageJSONRewrite(packageJSON, 'ACCESSTOKENHERE')
    expect(packageJSON).toEqual({
        dependencies: {
            '@connectedcars/some-project':
                'git+https://ACCESSTOKENHERE:@github.com/connectedcars/some-project'
        }
    })
})