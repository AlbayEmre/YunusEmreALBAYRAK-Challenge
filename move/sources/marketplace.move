module challenge::marketplace;

use challenge::hero::Hero;
use sui::coin::{Self, Coin};
use sui::event;
use sui::object;
use sui::sui::SUI;
use sui::transfer;
use sui::tx_context::{TxContext, sender, epoch_timestamp_ms};

// ========= ERRORS =========

const EInvalidPayment: u64 = 1;

// ========= STRUCTS =========

public struct ListHero has key, store {
    id: UID,
    nft: Hero,
    price: u64,
    seller: address,
}

// ========= CAPABILITIES =========

public struct AdminCap has key, store {
    id: UID,
}

// ========= EVENTS =========

public struct HeroListed has copy, drop {
    list_hero_id: ID,
    price: u64,
    seller: address,
    timestamp: u64,
}

public struct HeroBought has copy, drop {
    list_hero_id: ID,
    price: u64,
    buyer: address,
    seller: address,
    timestamp: u64,
}

// ========= FUNCTIONS =========

// 1️⃣ MODULE INITIALIZATION
fun init(ctx: &mut TxContext) {
    // AdminCap oluştur
    let admin = AdminCap {
        id: object::new(ctx),
    };

    // AdminCap’i modül yayınlayıcısına gönder
    transfer::public_transfer(admin, sender(ctx));
}

// 2️⃣ HEROYU LİSTEYE EKLE
public fun list_hero(nft: Hero, price: u64, ctx: &mut TxContext) {
    let list_hero = ListHero {
        id: object::new(ctx),
        nft,
        price,
        seller: sender(ctx),
    };

    // Event yayınla
    event::emit(HeroListed {
        list_hero_id: object::id(&list_hero),
        price,
        seller: sender(ctx),
        timestamp: epoch_timestamp_ms(ctx),
    });

    // Herkes görebilsin diye paylaş
    transfer::share_object(list_hero);
}

// 3️⃣ HERO SATIN ALMA
#[allow(lint(self_transfer))]
public fun buy_hero(list_hero: ListHero, coin: Coin<SUI>, ctx: &mut TxContext) {
    let ListHero { id, nft, price, seller } = list_hero;

    // Ödeme doğrulama
    assert!(coin::value(&coin) == price, EInvalidPayment);

    // Ödeme satıcıya gönder
    transfer::public_transfer(coin, seller);

    // NFT’yi alıcıya gönder
    transfer::public_transfer(nft, sender(ctx));

    // Event yayınla
    event::emit(HeroBought {
        list_hero_id: object::uid_to_inner(&id),
        price,
        buyer: sender(ctx),
        seller,
        timestamp: epoch_timestamp_ms(ctx),
    });

    // Liste objesini sil
    object::delete(id);
}

// ========= ADMIN FUNCTIONS =========

// 4️⃣ ADMIN DELIST
public fun delist(_: &AdminCap, list_hero: ListHero) {
    let ListHero { id, nft, price: _, seller } = list_hero;

    // NFT’yi satıcıya geri gönder
    transfer::public_transfer(nft, seller);

    // Liste objesini sil
    object::delete(id);
}

// 5️⃣ ADMIN FİYAT DEĞİŞTİR
public fun change_the_price(_: &AdminCap, list_hero: &mut ListHero, new_price: u64) {
    list_hero.price = new_price;
}

// ========= GETTER FUNCTIONS =========

#[test_only]
public fun listing_price(list_hero: &ListHero): u64 {
    list_hero.price
}

// ========= TEST ONLY FUNCTIONS =========

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };
    transfer::public_transfer(admin_cap, sender(ctx));
}
