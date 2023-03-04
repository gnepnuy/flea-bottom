// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

  //deploy nft 
  const TestNFT = await hre.ethers.getContractFactory("TestNFT");
  const testNFT = await TestNFT.deploy();
  await testNFT.deployed();
  console.log('TestNFT address:',testNFT.address);

  //mint TestNFT
  const {singer_seller,singer_buyer} = hre.ethers.getSigners();
  const tokenURI = 'www.baidu.com';
  await testNFT.mint(singer.address,tokenURI);

  //deploy FleaBottom
  const FleaBottom = await hre.ethers.getContractFactory("FleaBottomV2");
  const fleaBottom = await FleaBottom.deploy();
  await fleaBottom.deployed();
  console.log("fleaBottom deployed to:", fleaBottom.address);

  //nft 授权给fleabottom
  await testNFT.setApprovalForAll(fleaBottom.address,true);

  //生成订单
  const sell_order = {

  }

  const sell_input = {

  }

  const buy_order = {

  }

  const buy_input = {

  }

  //签名

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
