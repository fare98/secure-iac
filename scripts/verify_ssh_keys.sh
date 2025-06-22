#!/bin/bash
# Script to verify SSH key pair matches

echo "Verifying SSH key pair..."

# Extract public key from terraform.tfvars.json
PUBLIC_KEY_FROM_CONFIG=$(jq -r '.ssh_public_key' ../terraform/terraform.tfvars.json)

# Path to your private key (adjust if needed)
PRIVATE_KEY_PATH="$1"

if [ -z "$PRIVATE_KEY_PATH" ]; then
    echo "Usage: $0 <path_to_private_key>"
    echo "Example: $0 ~/.ssh/id_rsa"
    exit 1
fi

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "Error: Private key file not found: $PRIVATE_KEY_PATH"
    exit 1
fi

# Generate public key from private key
echo "Generating public key from private key..."
PUBLIC_KEY_FROM_PRIVATE=$(ssh-keygen -y -f "$PRIVATE_KEY_PATH" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Could not generate public key from private key. Is the file a valid SSH private key?"
    exit 1
fi

# Compare the keys
echo ""
echo "Public key in terraform.tfvars.json:"
echo "$PUBLIC_KEY_FROM_CONFIG"
echo ""
echo "Public key generated from private key:"
echo "$PUBLIC_KEY_FROM_PRIVATE"
echo ""

if [ "$PUBLIC_KEY_FROM_CONFIG" = "$PUBLIC_KEY_FROM_PRIVATE" ]; then
    echo "✅ SUCCESS: SSH keys match!"
else
    echo "❌ ERROR: SSH keys do NOT match!"
    echo ""
    echo "The public key in terraform.tfvars.json does not match the private key."
    echo "You need to either:"
    echo "1. Update terraform.tfvars.json with the correct public key"
    echo "2. Use the correct private key in Jenkins credentials"
fi