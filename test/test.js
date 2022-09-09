const privateModule = require('@connectedcars/private-module')
const expect = require('chai').expect;
const { MySQLServer, MySQLClient } = require('@connectedcars/test')

describe('test.js', () => {
  it('say Hello world', (done) => {
    expect("Hello world").to.equal(privateModule())
    done()
  });
  
  it('should start mysqld and get the version with SQL', async () => {
    const mySqlServer = new MySQLServer()
    let mySqlClient
    try {
      mySqlClient = new MySQLClient({ port: await mySqlServer.getListenPort() })
      const pool = await mySqlClient.getConnectionPool('mysql')
      const databases = (await mySqlClient.query(pool,
        `
          SHOW VARIABLES LIKE 'version';
        `
      )).map(r => `${r.Value}`)
      expect(databases).to.match(/^(5\.7|8\.)/)
      expect(databases.indexOf('5.7.21')).to.equal(-1)
      mySqlClient.cleanup()
    } finally {
      mySqlClient.cleanup()
      mySqlServer.kill()
    }
  }).timeout(60000);;
});