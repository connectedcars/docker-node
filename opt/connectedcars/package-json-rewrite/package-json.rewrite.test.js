const { packageJSONRewrite, packageLockJSONRewrite } = require('./package-json-rewrite')

test('replace all git+ssh with http', () => {
    let packageJSON = {
        dependencies: {
            'awesome-module':
                'git+ssh://git@github.com/connectedcars/awesome-module.git'
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