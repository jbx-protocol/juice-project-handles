import { expect } from "chai";
import { Contract, Signer } from "ethers";
import fs from "fs";
import { ethers } from "hardhat";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";
import { before } from "mocha";

import {
  ENSDeployer,
  ENSRegistry,
  FIFSRegistrar,
  JBProjectHandles,
  PublicResolver,
  TestJBProjects
} from "../typechain-types";
import { labelhash, namehash } from "./utils";

const configEnsName = (domain: string) => domain.split(".").reverse();

const ens1 = configEnsName("sub.project1.eth");
const ens2 = configEnsName("project2.eth");

const ensTextKey = "juicebox";

let wallets: Record<
  "project1Owner" | "project2Owner" | "ensOwner",
  SignerWithAddress
>;

let resolver: PublicResolver;
let registrar: FIFSRegistrar;
let registry: ENSRegistry;
let jbProjects: TestJBProjects;
let jbProjectHandles: JBProjectHandles;
let jbOperatorStore: TestJBOperatorStore;

async function setupWallets() {
  const [ensOwner, project1Owner, project2Owner] = await ethers.getSigners();

  wallets = {
    project1Owner,
    project2Owner,
    ensOwner, // Note: Owner of ENS names is irrelevant
  };
}

async function setupEns() {
  const EnsDeployer = await ethers.getContractFactory("ENSDeployer");
  const ensDeployer = (await EnsDeployer.deploy()) as ENSDeployer;

  resolver = (await ethers.getContractFactory("PublicResolver")).attach(
    await ensDeployer.publicResolver()
  ) as PublicResolver;
  registrar = (await ethers.getContractFactory("FIFSRegistrar")).attach(
    await ensDeployer.fifsRegistrar()
  ) as FIFSRegistrar;
  registry = (await ethers.getContractFactory("ENSRegistry")).attach(
    await ensDeployer.ens()
  ) as ENSRegistry;
}

async function deployTestJBProjects() {
  const JBProjects = await ethers.getContractFactory("TestJBProjects");
  jbProjects = (await JBProjects.deploy("JBProjects", "JBP")) as TestJBProjects;
}

async function deployJBProjectHandles(
  jbProjectsAddress: string,
  ensResolverAddress: string,
  jbOperatorStoreAddress: string,
) {
  const JBProjectHandlesFactory = await ethers.getContractFactory(
    "JBProjectHandles"
  );
  jbProjectHandles = (await JBProjectHandlesFactory.deploy(
    jbProjectsAddress,
    ensResolverAddress,
    jbOperatorStoreAddress
  )) as JBProjectHandles;
}

// Instantiate JBProjectHandles contract with specific signer
export const jbProjectHandlesContract = (signer?: Signer) =>
  new Contract(
    jbProjectHandles.address,
    JSON.parse(
      fs
        .readFileSync(
          "./artifacts/contracts/JBProjectHandles.sol/JBProjectHandles.json"
        )
        .toString()
    ).abi,
    signer ?? ethers.provider
  ) as JBProjectHandles;

before(async () => {
  await setupWallets();
  await setupEns();
  await deployTestJBProjects();

  // Create JB projects to owner 1 and owner 2 addresses
  await jbProjects.mint(wallets.project1Owner.address);
  await jbProjects.mint(wallets.project2Owner.address);

  expect(await jbProjects.ownerOf(1)).to.equal(wallets.project1Owner.address);
  expect(await jbProjects.ownerOf(2)).to.equal(wallets.project2Owner.address);

  // Register ENS name 1 with subdomain to ensOwner address
  await registrar.register(labelhash(ens1[1]), wallets.ensOwner.address);
  await registry.setSubnodeRecord(
    namehash([ens1[1], ens1[0]].join(".")),
    labelhash(ens1[2]),
    wallets.ensOwner.address,
    resolver.address,
    100000
  );

  // Register ENS name 2 to ensOwner address
  await registrar.register(labelhash(ens2[1]), wallets.ensOwner.address);
});

describe("JBProjectHandles", function () {
  it("Should deploy", async function () {
    await deployJBProjectHandles(jbProjects.address, resolver.address, jbOperatorStore.address);

    expect(await jbProjectHandles.ensTextResolver()).to.equal(resolver.address);
    expect(await jbProjectHandles.jbProjects()).to.equal(jbProjects.address);
  });

  it("Should have empty handles for project with no ens name", async function () {
    expect(await jbProjectHandles.handleOf(1)).to.equal("");
    expect(await jbProjectHandles.handleOf(2)).to.equal("");
  });

  it("Set ENS name should emit event", async function () {
    // Set ENS name with subdomain
    await expect(
      jbProjectHandlesContract(
        wallets.project1Owner
      ).setEnsNameWithSubdomainFor(1, ens1[1], ens1[2])
    )
      .to.emit(jbProjectHandles, "SetEnsName")
      .withArgs(1, [ens1[2], ens1[1]].join("."));

    // Set ENS name without subdomain
    await expect(
      jbProjectHandlesContract(wallets.project2Owner).setEnsNameFor(2, ens2[1])
    )
      .to.emit(jbProjectHandles, "SetEnsName")
      .withArgs(2, ens2[1]);
  });

  it("Set ENS name should revert if not called by project owner", async function () {
    // Call for project2 by project1 owner
    await expect(
      jbProjectHandlesContract(
        wallets.project1Owner
      ).setEnsNameWithSubdomainFor(2, ens1[1], ens1[2])
    ).to.be.revertedWith(
      `NotJuiceboxProjectOwner(${2}, "${wallets.project1Owner.address}")`
    );
  });

  it("Should return empty handle for project with ens name but no reverse ID", async function () {
    const ensName1 = await jbProjectHandles.ensNameOf(1);
    expect(ensName1.name).to.equal(ens1[1]);
    expect(ensName1.subdomain).to.equal(ens1[2]);
    expect(await jbProjectHandles.handleOf(1)).to.equal("");

    const ensName2 = await jbProjectHandles.ensNameOf(2);
    expect(ensName2.name).to.equal(ens2[1]);
    expect(ensName2.subdomain).to.equal("");
    expect(await jbProjectHandles.handleOf(2)).to.equal("");
  });

  it("Should return correct handle for project with matching reverse ID on ENS name", async function () {
    // Set text records on ENS name with correct reverse ID
    await resolver.setText(
      namehash([...ens1].reverse().join(".")),
      ensTextKey,
      "1"
    );
    await resolver.setText(
      namehash([...ens2].reverse().join(".")),
      ensTextKey,
      "2"
    );

    expect(await jbProjectHandles.handleOf(1)).to.equal(
      [ens1[2], ens1[1]].join(".")
    );
    expect(await jbProjectHandles.handleOf(2)).to.equal(ens2[1]);
  });

  it("Should return empty handle for project with incorrect reverse ID on ENS name", async function () {
    // Set text records on ENS name with incorrect reverse ID
    await resolver.setText(
      namehash([...ens1].reverse().join(".")),
      ensTextKey,
      "69"
    );
    await resolver.setText(
      namehash([...ens2].reverse().join(".")),
      ensTextKey,
      "420"
    );

    expect(await jbProjectHandles.handleOf(1)).to.equal("");
    expect(await jbProjectHandles.handleOf(2)).to.equal("");
  });
});
