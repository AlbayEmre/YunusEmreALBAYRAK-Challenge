import { Transaction } from "@mysten/sui/transactions";

export const changePrice = (packageId: string, listHeroId: string, newPriceInSui: string, adminCapId: string) => {
  const tx = new Transaction();
  
  const newPriceInMist = BigInt(newPriceInSui) * BigInt(1000000000);

  tx.moveCall({
    target: `${packageId}::marketplace::change_the_price`,
    arguments: [tx.object(adminCapId), tx.object(listHeroId), tx.pure.u64(newPriceInMist)],
  });
  
  return tx;
};
