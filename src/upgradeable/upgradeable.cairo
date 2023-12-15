#[starknet::component]
mod UpgradeableComponent {
    use starknet::ClassHash;

    #[storage]
    struct Storage {
        version: u128,
        class_hash: ClassHash
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Upgraded: Upgraded
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        class_hash: ClassHash,
        previous_class_hash: ClassHash,
        version: u128
    }

    mod Errors {
        const INVALID_CLASS: felt252 = 'Class hash cannot be zero';
        const SAME_CLASS: felt252 = 'Class hash cannot be the same';
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn _upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            assert(!new_class_hash.is_zero(), Errors::INVALID_CLASS);

            let previous_class_hash: ClassHash = self.class_hash.read();
            assert(previous_class_hash != new_class_hash, Errors::SAME_CLASS);

            starknet::replace_class_syscall(new_class_hash).unwrap();
            let version: u128 = self.version.read() + 1;
            self.class_hash.write(new_class_hash);
            self.version.write(version);
            self.emit(Upgraded { class_hash: new_class_hash, previous_class_hash, version });
        }
    }
}
