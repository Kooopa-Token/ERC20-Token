const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const KooopaToken = artifacts.require("KartRacer");

module.exports = async function(deployer) {
  const instance = await deployProxy(KooopaToken, [], { deployer: deployer, kind: 'uups'});
//   const instance = await upgradeProxy("0xf46b919dd731aeee7244fa63849ed0300cb540fa", KooopaToken, [], { deployer: deployer, kind: 'uups', });
  console.log('deployed', instance)
};