import hashlib
import base64

def generate_scada_hash(plaintext):
    # Compute the SHA-1 hash of the plaintext
    sha1_hash = hashlib.sha1(plaintext.encode()).hexdigest()

    # Unhex (convert hex to bytes)
    sha1_bytes = bytes.fromhex(sha1_hash)

    # Base64 encode the bytes
    base64_encoded = base64.b64encode(sha1_bytes)

    # Return the Base64 encoded string as a decoded string
    return base64_encoded.decode()

plaintext = "pSCyQYjV2CEDMY8Z6j9k" # use 20char passwords only!
hash_result = generate_scada_hash(plaintext)
print(f"Generated hash: {hash_result}")
