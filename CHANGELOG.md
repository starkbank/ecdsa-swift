# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to the following versioning pattern:

Given a version number MAJOR.MINOR.PATCH, increment:

- MAJOR version when **breaking changes** are introduced;
- MINOR version when **backwards compatible changes** are introduced;
- PATCH version when backwards compatible bug **fixes** are implemented.


## [Unreleased]

## [2.0.1] - 2026-11-11
### Fixed
- random integer generation filling only part of the buffer, which weakened private keys and signature nonces
- unchecked SecRandomCopyBytes status, which could produce predictable private keys and signature nonces
