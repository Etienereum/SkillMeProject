const AuctionFactory = artifacts.require("AuctionFactory");
const SkillMeToken = artifacts.require("SkillMeToken");

module.exports = function (deployer) {
  deployer.deploy(SkillMeToken, 1000000).then(function () {
    console.log("Token deployed at: ", SkillMeToken.address)
    return deployer.deploy(AuctionFactory, SkillMeToken.address);
  });
};
