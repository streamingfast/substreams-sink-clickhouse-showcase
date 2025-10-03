mod abi;
mod pb;
use hex_literal::hex;
use pb::contract::v1 as contract;
use substreams::Hex;
use substreams_ethereum::pb::eth::v2 as eth;
use substreams_ethereum::Event;

#[allow(unused_imports)]
use num_traits::cast::ToPrimitive;

substreams_ethereum::init!();

const USDC_TRACKED_CONTRACT: [u8; 20] = hex!("a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");

#[substreams::handlers::map]
fn map_transfer(blk: eth::Block) -> Result<contract::Output, substreams::errors::Error> {
    let mut output = contract::Output::default();
    output.transfers.append(&mut blk
        .receipts()
        .flat_map(|view| {
            view.receipt.logs.iter()
                .filter(|log| log.address == USDC_TRACKED_CONTRACT)
                .filter_map(|log| {
                    if let Some(event) = abi::usdc_contract::events::Transfer::match_and_decode(log) {
                        return Some(contract::Transfer {
                            trx_hash: Hex(&view.transaction.hash).to_string(),
                            from: event.from,
                            to: event.to,
                            amount: event.value.to_string(),
                        });
                    }

                    None
                })
        })
        .collect());
    Ok(output)
}