// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

// https://chenglongma.com/10/simple-keccak/
// https://github.com/firefly/wallet/blob/master/source/libs/ethers/src/keccak256.c

library Lib_Keccak256 {
  struct CTX {
    uint64[25] A;
  }

  function ROTL64(uint64 qword, uint64 n) internal pure returns (uint64) {
    return ((qword) << (n) ^ ((qword) >> (64 - (n))));
  }

  function get_round_constant(uint round) internal pure returns (uint64) {
    uint64 result = 0;
    uint8 roundInfo = uint8(0x7421587966164852535d4f3f26350c0e5579211f705e1a01 >> (round*8));
    result |= (uint64(roundInfo) << (63-6)) & (1 << 63);
    result |= (uint64(roundInfo) << (31-5)) & (1 << 31);
    result |= (uint64(roundInfo) << (15-4)) & (1 << 15);
    result |= (uint64(roundInfo) << (7-3)) & (1 << 7);
    result |= (uint64(roundInfo) << (3-2)) & (1 << 3);
    result |= (uint64(roundInfo) << (1-1)) & (1 << 1);
    result |= (uint64(roundInfo) << (0-0)) & (1 << 0);
    return result;
  }

  function keccak_theta_rho_pi(CTX memory c) internal pure {
    uint64 C0 = c.A[0] ^ c.A[5] ^ c.A[10] ^ c.A[15] ^ c.A[20];
    uint64 C1 = c.A[1] ^ c.A[6] ^ c.A[11] ^ c.A[16] ^ c.A[21];
    uint64 C2 = c.A[2] ^ c.A[7] ^ c.A[12] ^ c.A[17] ^ c.A[22];
    uint64 C3 = c.A[3] ^ c.A[8] ^ c.A[13] ^ c.A[18] ^ c.A[23];
    uint64 C4 = c.A[4] ^ c.A[9] ^ c.A[14] ^ c.A[19] ^ c.A[24];
    uint64 D0 = ROTL64(C1, 1) ^ C4;
    uint64 D1 = ROTL64(C2, 1) ^ C0;
    uint64 D2 = ROTL64(C3, 1) ^ C1;
    uint64 D3 = ROTL64(C4, 1) ^ C2;
    uint64 D4 = ROTL64(C0, 1) ^ C3;
    c.A[0] ^= D0;
    uint64 A1 = ROTL64(c.A[1] ^ D1, 1);
    c.A[1] = ROTL64(c.A[6] ^ D1, 44);
    c.A[6] = ROTL64(c.A[9] ^ D4, 20);
    c.A[9] = ROTL64(c.A[22] ^ D2, 61);
    c.A[22] = ROTL64(c.A[14] ^ D4, 39);
    c.A[14] = ROTL64(c.A[20] ^ D0, 18);
    c.A[20] = ROTL64(c.A[2] ^ D2, 62);
    c.A[2] = ROTL64(c.A[12] ^ D2, 43);
    c.A[12] = ROTL64(c.A[13] ^ D3, 25);
    c.A[13] = ROTL64(c.A[19] ^ D4, 8);
    c.A[19] = ROTL64(c.A[23] ^ D3, 56);
    c.A[23] = ROTL64(c.A[15] ^ D0, 41);
    c.A[15] = ROTL64(c.A[4] ^ D4, 27);
    c.A[4] = ROTL64(c.A[24] ^ D4, 14);
    c.A[24] = ROTL64(c.A[21] ^ D1, 2);
    c.A[21] = ROTL64(c.A[8] ^ D3, 55);
    c.A[8] = ROTL64(c.A[16] ^ D1, 45);
    c.A[16] = ROTL64(c.A[5] ^ D0, 36);
    c.A[5] = ROTL64(c.A[3] ^ D3, 28);
    c.A[3] = ROTL64(c.A[18] ^ D3, 21);
    c.A[18] = ROTL64(c.A[17] ^ D2, 15);
    c.A[17] = ROTL64(c.A[11] ^ D1, 10);
    c.A[11] = ROTL64(c.A[7] ^ D2, 6);
    c.A[7] = ROTL64(c.A[10] ^ D0, 3);
    c.A[10] = A1;
  }

  function keccak_chi(CTX memory c) internal pure {
    uint i;
    uint64 A0;
    uint64 A1;
    for (i = 0; i < 25; i+=5) {
      A0 = c.A[0 + i];
      A1 = c.A[1 + i];
      c.A[0 + i] ^= ~A1 & c.A[2 + i];
      c.A[1 + i] ^= ~c.A[2 + i] & c.A[3 + i];
      c.A[2 + i] ^= ~c.A[3 + i] & c.A[4 + i];
      c.A[3 + i] ^= ~c.A[4 + i] & A0;
      c.A[4 + i] ^= ~A0 & A1;
    }
  }

  function keccak_init(CTX memory c) internal pure {
    // is this needed?
    uint i;
    for (i = 0; i < 25; i++) {
      c.A[i] = 0;
    }
  }

  function sha3_permutation(CTX memory c) internal pure {
    uint round;
    for (round = 0; round < 24; round++) {
      keccak_theta_rho_pi(c);
      keccak_chi(c);
      // keccak_iota
      c.A[0] ^= get_round_constant(round);
    }
  }

  // https://stackoverflow.com/questions/2182002/convert-big-endian-to-little-endian-in-c-without-using-provided-func
  function flip(uint64 val) internal pure returns (uint64) {
    val = ((val << 8) & 0xFF00FF00FF00FF00 ) | ((val >> 8) & 0x00FF00FF00FF00FF );
    val = ((val << 16) & 0xFFFF0000FFFF0000 ) | ((val >> 16) & 0x0000FFFF0000FFFF );
    return (val << 32) | (val >> 32);
  }

  function get_hash(CTX memory c) internal pure returns (bytes32) {
    return bytes32((uint256(flip(c.A[0])) << 192) |
                   (uint256(flip(c.A[1])) << 128) |
                   (uint256(flip(c.A[2])) << 64) |
                   (uint256(flip(c.A[3])) << 0));
  }

}