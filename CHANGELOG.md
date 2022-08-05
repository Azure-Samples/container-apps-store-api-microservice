## Changelog

# Prep for Azure Docs (2022-08-05)

*Features*
- Moved the `Build and Run` section to its own independent markdown file 

*Bug Fixes*
- Updated Bicep to use stable, GA APIs for Container Apps 

*Breaking Changes*
- Updated to use GITHUB.TOKEN instead of asking user to create a PAT (Personal Access Token). Users will need to delete images from GHCR using the PAT in order to write images to GHCR using the GITHUB.TOKEN
- Removed outdated Tye references 
