const packageAuth = require('./Operations')

test('package-auth should be defined', () => {
  expect(packageAuth.rewrite).toBeInstanceOf(Function)
})

test('package-auth to replace all git+ssh with http', () => {
  const result = packageAuth.rewrite('ACCESSTOKENHERE', {
    dependencies: {
      'awesome-module':
        'git+ssh://git@github.com/connectedcars/awesome-module.git#semver:^v1.0.0',
    },
  })

  expect(result).toEqual({
    dependencies: {
      'awesome-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/awesome-module.git#semver:^v1.0.0',
    },
  })
})

test('package-auth to revert all http to ssh', () => {
  const result = packageAuth.revert({
    dependencies: {
      'awesome-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/awesome-module.git#semver:^v1.0.0',
    },
  })

  expect(result).toEqual({
    dependencies: {
      'awesome-module':
        'git+ssh://git@github.com/connectedcars/awesome-module.git#semver:^v1.0.0',
    },
  })
})

test('package-auth to replace all [provider]:', () => {
  const result = packageAuth.rewrite('ACCESSTOKENHERE', {
    dependencies: {
      'github-module': 'github:connectedcars/github-module#semver:^v1.0.0',
    },
  })

  expect(result).toEqual({
    dependencies: {
      'github-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/github-module.git#semver:^v1.0.0',
    },
  })
})

test('package-auth to replace all [provider]:', () => {
  const result = packageAuth.revert({
    dependencies: {
      'github-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/github-module.git#semver:^v1.0.0',
    },
  })

  expect(result).toEqual({
    dependencies: {
      'github-module': 'github:connectedcars/github-module#semver:^v1.0.0',
    },
  })
})
