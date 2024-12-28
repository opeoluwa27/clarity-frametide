import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new album",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "create-album", [
                types.ascii("My Vacation"),
                types.ascii("Summer 2023 photos"),
                types.bool(true)
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can add photo to album",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "create-album", [
                types.ascii("My Vacation"),
                types.ascii("Summer 2023 photos"),
                types.bool(true)
            ], wallet_1.address),
            Tx.contractCall("photo_album", "add-photo", [
                types.uint(1),
                types.ascii("QmHash123"),
                types.ascii("Beach sunset")
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        block.receipts[1].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can add collaborator to album",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "create-album", [
                types.ascii("My Vacation"),
                types.ascii("Summer 2023 photos"),
                types.bool(true)
            ], wallet_1.address),
            Tx.contractCall("photo_album", "add-collaborator", [
                types.uint(1),
                types.principal(wallet_2.address),
                types.bool(true),
                types.bool(false)
            ], wallet_1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can like photo",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "create-album", [
                types.ascii("My Vacation"),
                types.ascii("Summer 2023 photos"),
                types.bool(true)
            ], wallet_1.address),
            Tx.contractCall("photo_album", "add-photo", [
                types.uint(1),
                types.ascii("QmHash123"),
                types.ascii("Beach sunset")
            ], wallet_1.address),
            Tx.contractCall("photo_album", "like-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        block.receipts[2].result.expectOk().expectBool(true);
        
        // Verify like count
        let photoBlock = chain.mineBlock([
            Tx.contractCall("photo_album", "get-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        let photo = photoBlock.receipts[0].result.expectOk().expectTuple();
        assertEquals(photo['likes'], types.uint(1));
    }
});