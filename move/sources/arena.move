module challenge::arena;

use challenge::hero::{Hero, hero_power};
use sui::object;
use sui::transfer;
use sui::event;
use sui::tx_context::{TxContext, sender, epoch_timestamp_ms};

// ========= STRUCTS =========

public struct Arena has key, store {
    id: UID,
    warrior: Hero,
    owner: address,
}

// ========= EVENTS =========

public struct ArenaCreated has copy, drop {
    arena_id: ID,
    timestamp: u64,
}

public struct ArenaCompleted has copy, drop {
    winner_hero_id: ID,
    loser_hero_id: ID,
    timestamp: u64,
}

// ========= FUNCTIONS =========

public fun create_arena(hero: Hero, ctx: &mut TxContext) {
    // 1️⃣ Yeni arena oluştur
    let arena = Arena {
        id: object::new(ctx),
        warrior: hero,
        owner: sender(ctx),
    };

    // 2️⃣ Olay (event) yayınla
    event::emit(ArenaCreated {
        arena_id: object::id(&arena),
        timestamp: epoch_timestamp_ms(ctx),
    });

    // 3️⃣ Arenayı herkesle paylaş (battle yapılabilsin)
    transfer::share_object(arena);
}

#[allow(lint(self_transfer))]
public fun battle(hero: Hero, arena: Arena, ctx: &mut TxContext) {
    let Arena { id, warrior, owner } = arena;

    let hero_id = object::id(&hero);
    let warrior_id = object::id(&warrior);

    // 1️⃣ Güç karşılaştırması
    if (hero_power(&hero) > hero_power(&warrior)) {
        // 🏆 Hero kazandı
        transfer::public_transfer(hero, sender(ctx));
        transfer::public_transfer(warrior, sender(ctx));

        event::emit(ArenaCompleted {
            winner_hero_id: hero_id,
            loser_hero_id: warrior_id,
            timestamp: epoch_timestamp_ms(ctx),
        });
    } else {
        // 💀 Warrior kazandı
        transfer::public_transfer(hero, owner);
        transfer::public_transfer(warrior, owner);

        event::emit(ArenaCompleted {
            winner_hero_id: warrior_id,
            loser_hero_id: hero_id,
            timestamp: epoch_timestamp_ms(ctx),
        });
    };

    // 2️⃣ Arena nesnesini sil
    object::delete(id);
}
