const packageAuth = require('./OperationsLock')

test('package-auth should be defined', () => {
  expect(packageAuth.rewriteLock).toBeInstanceOf(Function)
  expect(packageAuth.revertLock).toBeInstanceOf(Function)
})

test('package-auth to replace all lock git+ssh with http', () => {
  const result = packageAuth.rewriteLock('ACCESSTOKENHERE', {
    dependencies: {
      'private-module': {
        version:
          'git+ssh://git@github.com/connectedcars/private-module.git#f5ac051fbd50445582a6e741656508c08b2b6d25'
      }
    }
  })

  expect(result).toEqual({
    dependencies: {
      'private-module': {
        version:
          'git+https://ACCESSTOKENHERE:@github.com/connectedcars/private-module.git#f5ac051fbd50445582a6e741656508c08b2b6d25'
      }
    }
  })
})

test('package-auth to revert all lock http to ssh', () => {
  const result = packageAuth.revertLock({
    dependencies: {
      'private-module': {
        version:
          'git+https://ACCESSTOKENHERE:@github.com/connectedcars/private-module.git#f5ac051fbd50445582a6e741656508c08b2b6d25'
      }
    }
  })

  expect(result).toEqual({
    dependencies: {
      'private-module': {
        version:
          'git+ssh://git@github.com/connectedcars/private-module.git#f5ac051fbd50445582a6e741656508c08b2b6d25'
      }
    }
  })
})
