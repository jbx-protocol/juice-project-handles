import { toUtf8Bytes } from "ethers/lib/utils";
import { keccak_256 } from "js-sha3";

// Based on https://docs.ens.domains/contract-api-reference/name-processing

export function namehash(name?: string) {
  let node = "";
  for (let i = 0; i < 32; i++) {
    node += "00";
  }

  if (name) {
    const parts = name.split(".");

    for (let i = parts.length - 1; i >= 0; i--) {
      const labelSha = keccak_256(parts[i]);
      node = keccak_256(Buffer.from(node + labelSha, "hex"));
    }
  }

  return "0x" + node;
}

export function labelhash(label: string) {
  return "0x" + keccak_256(toUtf8Bytes(label));
}
