#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}


#[starknet::contract]
mod Counter {
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
use starknet::ContractAddress;
    use kill_switch::IKillSwitchDispatcherTrait;
    use kill_switch::IKillSwitchDispatcher;
    use openzeppelin::access::ownable::OwnableComponent;


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnerImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[constructor]
    fn constructor(ref self: ContractState, value: u32, address: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(value);
        self.kill_switch.write(address);
        self.ownable.initializer(initial_owner);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32
    }

    #[abi(embed_v0)]
    impl ICounterImpl of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let bool = IKillSwitchDispatcher { contract_address: self.kill_switch.read()}.is_active();
            self.ownable.assert_only_owner();
            assert!(bool == false, "Kill Switch is active");
            let mut amount = self.counter.read();
            amount += 1;
            self.counter.write(amount);
            // self.emit( OwnableEvent { contract_address: amount} )
            }
        }
    }
