# FrameTide

A decentralized collaborative photo album platform built on Stacks blockchain.

This smart contract enables users to:
- Create photo albums
- Add photos to albums (via photo hashes)
- Manage album collaborators
- Like and comment on photos
- Tag users in photos
- Set album visibility (public/private)

## Features
- Decentralized photo album ownership
- Collaborative album management
- Photo engagement tracking (likes, comments)
- User tagging with coordinates
- Access control mechanisms
- Comment system with user attribution
- Tag placement with x,y coordinates

## New Features
### Photo Comments
Users can now add comments to photos, with full attribution and timestamp tracking.
Comments are stored on-chain and can be retrieved with pagination support.

### User Tagging
Photos now support user tagging functionality:
- Tag users at specific x,y coordinates in photos
- Track who created each tag
- Store tag creation timestamps
- Count total tags per photo
