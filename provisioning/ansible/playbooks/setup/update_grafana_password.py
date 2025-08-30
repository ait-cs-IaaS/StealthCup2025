import hashlib
import binascii
from hashlib import pbkdf2_hmac

# use this script to create password hashes for grafana
# original go script:
# https://go.dev/play/p/t2rzj87i_en
# https://github.com/iamaldi/grafana2hashcat

def encode_password(password: str, salt: str) -> str:
    """
    Encode the password using PBKDF2 with SHA-256 as in the Grafana encoding process.
    The number of iterations is set to 10000, and the derived key length is 50 bytes.
    """
    # Convert password and salt to byte strings
    password_bytes = password.encode('utf-8')
    salt_bytes = salt.encode('utf-8')
    
    # Perform PBKDF2 HMAC SHA-256
    key = pbkdf2_hmac('sha256', password_bytes, salt_bytes, 10000, dklen=50)
    
    # Return the resulting key as a hexadecimal string
    return binascii.hexlify(key).decode('utf-8')

def main():
    # Test values
    test_salt = "pepper"
    test_password = "5f8k8DbXbAoxHftFExKHTzh3FCaZVj"
    
    # Create Grafana password hash
    test_hash = encode_password(test_password, test_salt)
    
    # Output the hash and the salt
    print(f"Hash: {test_hash}")
    print(f"Salt: {test_salt}")

if __name__ == "__main__":
    main()
