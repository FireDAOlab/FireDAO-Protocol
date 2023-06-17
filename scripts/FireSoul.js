
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("获取部署钱包地址:",await deployer.getAddress());
  console.log("获取部署钱包地址余额:", (await deployer.getBalance()).toString());
  //指定合约工程要部署的名称
  const Token = await ethers.getContractFactory("FireSoul");
  const token = await Token.deploy('0x5AC124e2d36F404007C7682D5c1a993d45b9a758','0x293dB4d98E2D904fA5E209D2313cEF5526Ee9879','0x8c7039Cce395BDF09b8b9EE99DA5aA536Fb3F7E4');
  await token.deployed();

  console.log("部署后合约地址:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
});
