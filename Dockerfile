FROM trailofbits/echidna

# Install solc-select for Solidity version management
RUN pip install solc-select

# Use solc-select to install and set the desired Solidity version
RUN solc-select install 0.8.20
RUN solc-select use 0.8.20
