const packageAuth = require('./Operations')

test('package-auth should be defined', () => {
  expect(packageAuth.rewrite).toBeInstanceOf(Function)
})

test('package-auth to replace all git+ssh with http', () => {
  const result = packageAuth.rewrite('ACCESSTOKENHERE', {
    dependencies: {
      'awesome-module':
        'git+ssh://git@github.com/connectedcars/awesome-module.git'
    }
  })

  expect(result).toEqual({
    dependencies: {
      'awesome-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/awesome-module.git'
    }
  })
})

test('package-auth to revert all http to ssh', () => {
  const result = packageAuth.revert({
    dependencies: {
      'awesome-module':
        'git+https://ACCESSTOKENHERE:@github.com/connectedcars/awesome-module.git'
    }
  })

  expect(result).toEqual({
    dependencies: {
      'awesome-module':
        'git+ssh://git@github.com/connectedcars/awesome-module.git'
    }
  })
})
