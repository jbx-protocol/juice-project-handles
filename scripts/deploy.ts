/* eslint no-use-before-define: "warn" */
import chalk from "chalk";
import fs from "fs";
import { ethers } from "hardhat";

import { JBProjectHandles } from "../typechain-types";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";

const network = process.env.HARDHAT_NETWORK;
const jbProjectsAddresses: Record<string, string> = {
  mainnet: "0xD8B4359143eda5B2d763E127Ed27c77addBc47d3",
};
const textResolverAddresses: Record<string, string> = {
  mainnet: "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41",
};

const getDeployer = async () => (await ethers.getSigners())[0];

const writeFiles = (
  contractName: string,
  contractAddress: string,
  args: string[]
) => {
  const contract = JSON.parse(
    fs
      .readFileSync(
        `artifacts/contracts/${contractName}.sol/${contractName}.json`
      )
      .toString()
  );

  fs.writeFileSync(
    `deployments/${network}/${contractName}.json`,
    `{
      "address": "${contractAddress}", 
      "abi": ${JSON.stringify(contract.abi, null, 2)}
  }`
  );

  fs.writeFileSync(
    `deployments/${network}/${contractName}.arguments.js`,
    `module.exports = [${args}];`
  );

  console.log(
    "⚡️ All contract artifacts saved to:",
    chalk.yellow(`deployments/${network}/${contractName}`),
    "\n"
  );
};

const deployJBProjectHandles = async (): Promise<
  JBProjectHandles | undefined
> => {
  if (!network) {
    console.error("Missing hardhat network");
    return;
  }

  const deployer: SignerWithAddress = await getDeployer();

  console.log("Deploying JBProjectHandles with the account:", deployer.address);

  const jbProjectsAddress = jbProjectsAddresses[network];
  const textResolverAddress = textResolverAddresses[network];

  const args = [jbProjectsAddress, textResolverAddress];

  console.log("Deploying with args:", args);

  const JBProjectHandlesFactory = await ethers.getContractFactory(
    "JBProjectHandles"
  );

  const jbProjectHandles = (await JBProjectHandlesFactory.deploy(...args)) as JBProjectHandles;

  console.log(
    chalk.green(` ✔ JBProjectHandles deployed for network:`),
    process.env.HARDHAT_NETWORK,
    "\n",
    chalk.magenta(jbProjectHandles.address),
    `tx: ${jbProjectHandles.deployTransaction.hash}`
  );

  writeFiles(
    "JBProjectHandles",
    jbProjectHandles.address,
    args.map((a) => JSON.stringify(a))
  );

  return jbProjectHandles;
};

const main = async () => {
  await deployJBProjectHandles();

  console.log("Done");
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
