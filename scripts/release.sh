#!/bin/bash

INSTALL_DIR="/opt/build"
UPGRADE=0

usage() {
  echo "Usage:"
  echo ""
  echo " Release Uniris node binary"
  echo ""
  echo "  " release.sh [-d  dir] " Specify the installation dir"
  echo "  " release.sh -u "       Upgrade the release"
  echo "  " release.sh -h "       Print the help usage"
  echo ""
}

while getopts :uhd: option
do
    case "${option}"
    in
        d) INSTALL_DIR=${OPTARG};;
        u) UPGRADE=1;;
        h)
          usage
          exit 0
          ;;
        *)
          usage
          exit 1
          ;;
    esac
done
shift $((OPTIND -1))

# Install updated versions of hex/rebar
mix local.rebar --force
mix local.hex --if-missing --force

export MIX_ENV=prod

# Fetch deps and compile
mix deps.get

# Builds WEB assets in production mode
cd assets && npm ci && npm run deploy && cd - && mix phx.digest

VERSION=$(grep 'version:' mix.exs | cut -d '"' -f2)
echo ""
echo "Version: ${VERSION}"
echo "Installation dir: ${INSTALL_DIR}"

mkdir -p ${INSTALL_DIR}/mainnet
mkdir -p ${INSTALL_DIR}/testnet

if [ $UPGRADE == 1 ]
then
    # Build upgrade releases
    echo "Build the upgrade release"
    MIX_ENV=prod mix distillery.release --upgrade
    MIX_ENV=dev mix distillery.release --upgrade

    echo "Copy upgraded release into ${INSTALL_DIR}/mainnet/releases/${VERSION}"
    echo "Copy upgraded release into ${INSTALL_DIR}/testnet/releases/${VERSION}"

    cp "_build/prod/rel/uniris_node/releases/${VERSION}/uniris_node.tar.gz" ${INSTALL_DIR}/mainnet/releases/${VERSION}
    cp "_build/dev/rel/uniris_node/releases/${VERSION}/uniris_node.tar.gz" ${INSTALL_DIR}/testnet/releases/${VERSION}

    echo "Run the upgrade"
    ${INSTALL_DIR}/mainnet/bin/uniris_node upgrade ${VERSION}
    ${INSTALL_DIR}/testnet/bin/uniris_node upgrade ${VERSION}
else
    # Build the releases

    echo "Generate release"
    MIX_ENV=prod mix distillery.release
    MIX_ENV=dev mix distillery.release

    echo "Install MainNet release"
    tar zxvf "_build/prod/rel/uniris_node/releases/${VERSION}/uniris_node.tar.gz" -C ${INSTALL_DIR}/mainnet

    echo "Install TestNet release"
    tar zxvf "_build/dev/rel/uniris_node/releases/${VERSION}/uniris_node.tar.gz" -C ${INSTALL_DIR}/testnet
fi

exit
