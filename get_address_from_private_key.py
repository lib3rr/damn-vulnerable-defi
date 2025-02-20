from eth_keys import keys
from eth_utils import to_checksum_address


private_key_hex_1 = "0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744"
private_key_hex_2 = "0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159"

def private_key_to_address(private_key_hex):
    private_key = keys.PrivateKey(bytes.fromhex(private_key_hex[2:]))
    public_key = private_key.public_key
    address = public_key.to_address()
    return to_checksum_address(address)


address_1 = private_key_to_address(private_key_hex_1)
address_2 = private_key_to_address(private_key_hex_2)

print(f"Address for Private Key 1: {address_1}")
print(f"Address for Private Key 2: {address_2}")
