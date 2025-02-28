#!/bin/bash

_ROOT="$(pwd)" && cd "$(dirname "$0")" && ROOT="$(pwd)"
PJROOT="$ROOT"

DILL_DIR="$PJROOT"

dill_proc_num=$(ps axu | grep -v grep | grep dill-node | grep alps | wc -l)
if [ $dill_proc_num -ne 1 ]; then
    echo "The number of dill-node processes is $dill_proc_num, not 1. Not allowed to add validator with this script"
    exit 1
fi

is_light=0
light_process=$(ps axu | grep -v grep | grep dill-node | grep alps | grep "\--light")
if [ "$light_process" != "" ];then
    echo "A light dill node is running"
    is_light=1
else
    echo "A full dill node running"
fi

# Define variables
KEYS_DIR="$DILL_DIR/validator_keys"
KEYSTORE_DIR="$DILL_DIR/keystore"
PASSWORD_FILE="$KEYS_DIR/keystore_password.txt"

if [ "$os_type" == "Linux" ];then
    # check env variables LC_ALL and LANG
    locale_a_value=$(locale -a)
    locale_a_lower_value=$(echo $locale_a_value | tr '[:upper:]' '[:lower:]')

    lc_all_value=$(echo "$LC_ALL")
    lc_all_lower_value=$(echo "$LC_ALL" | tr '[:upper:]' '[:lower:]' | sed 's/-//g')
    if ! echo $locale_a_lower_value | grep -q "\<$lc_all_lower_value\>"; then
        if echo $locale_a_lower_value | grep -q "c.utf8"; then
            export LC_ALL=C.UTF-8
            echo "LC_ALL value $lc_all_value not found in locale -a ($locale_a_value), and set to C.UTF-8 now"
        else
            echo "LC_ALL value $lc_all_value not found in locale -a ($locale_a_value), and can't set to C.UTF-8!!!"
        fi
    fi

    lang_value=$(echo "$LANG")
    lang_lower_value=$(echo "$LANG" | tr '[:upper:]' '[:lower:]' | sed 's/-//g')
    if ! echo $locale_a_lower_value | grep -q "\<$lang_lower_value\>"; then
        if echo $locale_a_lower_value | grep -q "c.utf8"; then
            export LANG=C.UTF-8
            echo "LANG value $lang_value not found in locale -a ($locale_a_value), and set to C.UTF-8 now"
        else
            echo "LANG value $lang_value not found in locale -a ($locale_a_value), and can'tset to C.UTF-8"
        fi
    fi
fi

echo ""
echo "********** Step 1: Generating Validator Keys **********"
echo ""

echo "Validator Keys are generated from a mnemonic"
mnemonic=""
timestamp=$(date +%s)
mnemonic_path="$DILL_DIR/validator_keys/mnemonic-$timestamp.txt"
cd $DILL_DIR
while true; do
    mne_src=2
    case "$mne_src" in
        "1")
            ./dill_validators_gen generate-mnemonic --mnemonic_path $mnemonic_path
            ret=$?
            if [ $ret -ne 0 ]; then
                echo "dill_validators_gen generate-mnemonic failed"
                exit 1
            fi
            mnemonic="$(cat $mnemonic_path)"

            # confirm the mnemonic saved
            #while true; do
            #    read -p "Please confirm you have or will back up this file, type 'yes' to continue: " read_yes
            #    if [ "$read_yes" == "yes" ];then
            #        break
            #    fi
            #done

            break
            ;;
        "2")
            existing_mnemonic="$DILL_SEED"
            if [[ $existing_mnemonic =~ ^([a-zA-Z]+[[:space:]]+){11,}[a-zA-Z]+$ ]]; then
                mnemonic="$existing_mnemonic"
                break
            else
                echo ""
                echo "[Error]Invalid mnemonic format. A valid mnemonic should consist of 12 or more space-separated words."
            fi
            ;;
        *)
            echo ""
            echo "[Error] $mne_src is not a valid mnemonic source option"
            ;;
    esac
done

# read password
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "$PASSWORD_FILE does not exist, cannot read the password set before"
    exit 1
fi
password=$(<"$PASSWORD_FILE")

echo ""
if [ $is_light -eq 1 ]; then
    echo "The token amount to be deposited is 3600. Press any key to continue..."    
    deposit_option=1
    deposit_amount=3600
else
    while true; do
        read -p "Please choose an option for deposit token amount [1, 3600, 2, 36000] [1]: " deposit_option
        deposit_option=${deposit_option:-1}  # Set default choice to 1
        case "$deposit_option" in
            "1" | "3600")
                deposit_amount=3600
                break
                ;;
            "2" | "36000")
                deposit_amount=36000
                break
                ;;
            *)
                echo ""
                echo "[Error] $deposit_option is not a valid option for deposit token amount"
                ;;
        esac
    done
fi
echo ""
echo "Withdrawal Adress: $WALLET_EVM"
echo ""
while true; do
    read -p "Please enter your withdrawal address: " with_addr
    if ! [[ $with_addr =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo "Invalid withdrawal address format. It should start with '0x' followed by 40 hexadecimal characters."
    else
        break
    fi
done

# Generate validator keys
if [ "$mne_src" == "1" ];then
    ./dill_validators_gen existing-mnemonic --mnemonic="$mnemonic" --num_validators=1 --validator_start_index=0 --chain=alps --deposit_amount=$deposit_amount --keystore_password="$password" --execution_address="$with_addr"
    ret=$?
else
    ./dill_validators_gen existing-mnemonic --mnemonic="$mnemonic" --num_validators=1 --chain=alps --deposit_amount=$deposit_amount --keystore_password="$password" --execution_address="$with_addr"
    ret=$?
fi

ret=$?
if [ $ret -ne 0 ]; then
    echo "dill_validators_gen existing-mnemonic failed"
    exit 1
fi

echo ""
echo "Step 1 Completed. Press any key to continue..."
echo ""  # Move to a new line after the key press

echo ""
echo "********** Step 2: Import keys **********"
echo ""

# Import your keys to your keystore
echo "Importing keys to keystore..."
./dill-node accounts import --alps --wallet-dir $KEYSTORE_DIR --keys-dir $KEYS_DIR --accept-terms-of-use --account-password-file $PASSWORD_FILE --wallet-password-file $PASSWORD_FILE
