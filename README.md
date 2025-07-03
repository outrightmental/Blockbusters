# Blockbusters

Fast-paced arcade competition built for the [Noisebridge 1v1 Coffee Table](https://www.noisebridge.net/wiki/Coffee_Table)

## Game Design

[Google Drive Folder](https://drive.google.com/drive/folders/1zN-aMi7VjPdOoOUz3s_HHYSwMC-8Zp1V?usp=sharing)

## Continuous Integration

When a tag is pushed to the repository, [this workflow](.github/workflows/release.yml) will automatically build the release artifacts and attach them to the tag.

To build & publish a release:
1. [Create a tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) at the commit you want to release. The tag should be the version name you want to give the release, e.g. `v2.1`
2. [Create a release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) based on the tag

E.g. to create **v2.1** we
1. Created the tag `v2.1` and pushed it to the repostory -- GitHub Actions then automatically [built and published](https://github.com/outrightmental/Blockbusters/actions/runs/16060245132) the artifacts and attached them to that tag.
2. Created [release v2.1](https://github.com/outrightmental/Blockbusters/releases/tag/v2.1) from tag `v2.1` -- The artifacts then appeared attached to that release
