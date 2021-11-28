#!/usr/bin/env bash

# Generate key stores and store them at Azure Key Vault

echo "------------------------------------"
echo "| WSO2 Cloud Deployment Key Stores |"
echo "------------------------------------"

# Logging functions
function log_info() {
    local string=$*
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')][INFO]: ${string}" >&1
}

function log_error() {
    local string=$*
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')][ERROR]: ${string}. Exiting !" >&1
    exit 1
}

function print_usage {
    echo -e "Usage: $0 [options]\n";
    echo -e "Options:\n";
    echo -e "--keystore-id                - Key Store Identifier [default: \"primary\"]";
    echo -e "--keystore-pass              - Password of the key store for WSO2 product [default: \"wso2carbon\"]";
    echo -e "--key-alias                  - Alias of the key entry in key store for WSO2 product [default: \"wso2carbon\"]";
    echo -e "--key-pass                   - Password of the key in key store for WSO2 product [default: \"wso2carbon\"]";
    echo -e "--sans                       - Comma separated list of Subject Alternative Names to be included [default: includes only \"localhost\"]";
    exit 1;
}

# Global variables
keystore_id="primary"
keystore_key_alias="wso2carbon"
keystore_pass="wso2carbon"
keystore_key_pass="wso2carbon"
input_hostnames=""

for arg in "$@"
do
    case ${arg} in
        --keystore-id=*)
        keystore_id="${arg#*=}"
        shift
        ;;
        --key-alias=*)
        keystore_key_alias="${arg#*=}"
        shift
        ;;
        --key-pass=*)
        keystore_key_pass="${arg#*=}"
        shift
        ;;
        --keystore-pass=*)
        keystore_pass="${arg#*=}"
        shift
        ;;
        --sans=*)
        input_hostnames="${arg#*=}"
        shift
        ;;
        *)
        others+=("$1")
        print_usage
        shift
        ;;
    esac
done

# Check if the WSO2 Product key store identifier has been defined
[[ -z "${keystore_id}" ]] && print_usage

echo "Key Store Identifier                        : ${keystore_id}"
echo "Key Alias for Key Store Key Entry           : ${keystore_key_alias}"

# Capture the location of executables of command line utility tools used
readonly KEYTOOL=$(which keytool)

# Check the availability of command line utility tools used
if [[ ! ${KEYTOOL} ]]
then
    log_error "Java Keytool not installed"
fi

# Define workspace directory structure
readonly SCRIPT_DIRECTORY=$(dirname "$0")
readonly WORKSPACE=${SCRIPT_DIRECTORY}/workspace

##################################################
# Cleans up the workspace directory
# Globals:
#   WORKSPACE: File system path to the workspace
# Arguments:
#   None
# Returns:
#   None
##################################################
function cleanup() {
    test -d "${WORKSPACE}" \
        && log_info "Cleaning up the workspace directory..." \
        && rm -rf "${WORKSPACE}" \
        && log_info "Done."
}

####################################################
# Generates the PFX based key store for WSO2 product
# Globals:
#   WORKSPACE: File system path to the output directory of the generated key store for WSO2 product
#   keystore_key_alias: Alias of the key entry in key store for WSO2 product
#   keystore_key_pass: Password of the key in key store for WSO2 product
#   keystore_pass: Password of the key store for WSO2 product
#   keystore_id: Key store Identifier
#   input_hostnames: Comma separated list of Subject Alternative Names to be included
# Arguments:
#   None
# Returns:
#   None
####################################################
function generate_keystore() {
    log_info "Extracting the input Subject Alternative Names (SANs)..."

    local hostnames=()
    local sans="dns:localhost"

    IFS=',' read -ra hostnames <<< "${input_hostnames}"
    unset IFS
    for hostname in "${hostnames[@]}"; do
        [[ "${hostname}" = "localhost" ]] && continue
        sans="${sans},dns:${hostname}"
    done

    log_info "Done."

    log_info "Generating keystore for the WSO2 product..."

    mkdir -p "${WORKSPACE}"

    if ! ${KEYTOOL} -genkey -alias "${keystore_key_alias}" -validity 10950 -keyalg RSA -keysize 4096 \
        -keystore "${WORKSPACE}/${keystore_id}KeyStore.jks" \
        -dname "CN=localhost,OU=Cloud,O=WSO2 Inc,L=SL,S=WS,C=LK" \
        -ext san="${sans}" \
        -storepass "${keystore_pass}" \
        -keypass "${keystore_key_pass}"
    then
        log_error "Failed to generate the keystore for the WSO2 product"
    else
        log_info "Done."
    fi
}

function main() {
    cleanup

    generate_keystore
}

main
