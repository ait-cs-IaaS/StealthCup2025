import re
import sys
from email import policy
from email.parser import BytesParser
from email.generator import BytesGenerator
from email.header import decode_header, make_header
from io import BytesIO

import glob
import os

# Replacement settings
REPLACEMENTS = {
    'ait.ac.at': 'plumetech.io',
    'AIT': 'Plumetech',
    'Felix Schuster': 'Redacted Sender',
    'Patrick Himler': 'Redacted Receiver',
    'Schuster Felix': 'Redacted Sender',
    'Himler Patrick': 'Redacted Receiver',
    'man1k.com': 'team01.ctf.plumetech.io',
}

# Redact email addresses and IPs
EMAIL_RE = re.compile(rb'[\w\.-]+@[\w\.-]+')
IP_RE = re.compile(rb'\b\d{1,3}(?:\.\d{1,3}){3}\b')
HOSTNAME_RE = re.compile(rb'\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b')

def redact_headers(headers: str) -> str:
    for key, val in REPLACEMENTS.items():
        headers = re.sub(re.escape(key), val, headers, flags=re.IGNORECASE)
    return headers

def decode_and_redact_header(value):
    try:
        decoded = str(make_header(decode_header(value)))
        return redact_headers(decoded)
    except:
        return value

def sanitize_message(msg):
    for header in ['From', 'To', 'Cc', 'Subject']:
        if header in msg:
            original = msg[header]
            redacted = decode_and_redact_header(original)
            msg.replace_header(header, redacted)

    # Sanitize email content
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() in ['text/plain', 'text/html']:
                payload = part.get_payload(decode=True)
                if payload:
                    redacted = sanitize_bytes(payload)
                    part.set_payload(redacted.decode(part.get_content_charset() or 'utf-8'), charset=part.get_content_charset())
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            redacted = sanitize_bytes(payload)
            msg.set_payload(redacted.decode(msg.get_content_charset() or 'utf-8'), charset=msg.get_content_charset())

    return msg

def sanitize_bytes(content: bytes) -> bytes:
    content = EMAIL_RE.sub(b'redacted@plumetech.io', content)
    content = IP_RE.sub(b'10.0.0.1', content)
    content = HOSTNAME_RE.sub(b'host.plumetech.io', content)
    for old, new in REPLACEMENTS.items():
        content = re.sub(old.encode(), new.encode(), content, flags=re.IGNORECASE)
    return content

def main(infile_path, outfile_path):
    with open(infile_path, 'rb') as f:
        msg = BytesParser(policy=policy.default).parse(f)

    sanitized = sanitize_message(msg)

    with open(outfile_path, 'wb') as out:
        gen = BytesGenerator(out, policy=policy.default)
        gen.flatten(sanitized)

    print(f"Sanitized email saved to {outfile_path}")

if __name__ == '__main__':
    if len(sys.argv) == 3:
        main(sys.argv[1], sys.argv[2])
    else:
        print("No specific args provided. Attempting to sanitize all matching 'FW_*.eml' files.")
        files = sorted(glob.glob("FW_*.eml"))
        if not files:
            print("No matching files found.")
            sys.exit(1)

        for idx, filename in enumerate(files):
            outfile = f"Sanitized_{idx+1}.eml"
            print(f"Sanitizing: {filename} → {outfile}")
            main(filename, outfile)