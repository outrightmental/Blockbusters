# Blockbusters

Fast-paced arcade competition built for the [Noisebridge 1v1 Coffee Table](https://www.noisebridge.net/wiki/Coffee_Table)

## Game Design

[Google Drive Folder](https://drive.google.com/drive/folders/1zN-aMi7VjPdOoOUz3s_HHYSwMC-8Zp1V?usp=sharing)

## Continuous Integration

When a tag is pushed to the repository, [this workflow](.github/workflows/release.yml) builds the release and attaches it to the tag.

E.g.
1. Create the tag `v2.1` -- GitHub Actions then [builds and publishes](https://github.com/outrightmental/Blockbusters/actions/runs/16060150225) an artifact attached to the tag.
2. Create [release v2.1](https://github.com/outrightmental/Blockbusters/releases/tag/v2.1) from the tag -- the artifact appears attached to the release
