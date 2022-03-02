const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  // console.log("line 4 - 1_initial_migration.js");
  deployer.deploy(Migrations);
  console.log("line 6- 1_initial_migration.js");
};
