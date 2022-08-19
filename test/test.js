const privateModule = require('@connectedcars/private-module')
const expect = require('chai').expect;

describe('test.js', () => {
  it('say Hello world', (done) => {
    expect("Hello world").to.equal(privateModule())
    done()
  });
});