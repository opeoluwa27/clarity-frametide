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
    name: "Can add comment to photo",
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
            Tx.contractCall("photo_album", "add-comment", [
                types.uint(1),
                types.uint(1),
                types.ascii("Beautiful photo!")
            ], wallet_2.address)
        ]);
        
        block.receipts[2].result.expectOk().expectUint(1);
        
        // Verify comment count
        let photoBlock = chain.mineBlock([
            Tx.contractCall("photo_album", "get-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        let photo = photoBlock.receipts[0].result.expectOk().expectTuple();
        assertEquals(photo['comment-count'], types.uint(1));
    }
});

Clarinet.test({
    name: "Can tag user in photo",
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
            Tx.contractCall("photo_album", "add-tag", [
                types.uint(1),
                types.uint(1),
                types.principal(wallet_2.address),
                types.uint(100),
                types.uint(200)
            ], wallet_1.address)
        ]);
        
        block.receipts[2].result.expectOk().expectUint(1);
        
        // Verify tag count
        let photoBlock = chain.mineBlock([
            Tx.contractCall("photo_album", "get-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        let photo = photoBlock.receipts[0].result.expectOk().expectTuple();
        assertEquals(photo['tag-count'], types.uint(1));
    }
});
