;; FrameTide Photo Album Contract

;; Constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALBUM_NOT_FOUND (err u101))
(define-constant ERR_PHOTO_NOT_FOUND (err u102))
(define-constant ERR_INVALID_ALBUM (err u103))

;; Data Maps
(define-map albums 
    { album-id: uint }
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        is-public: bool,
        created-at: uint
    }
)

(define-map photos
    { album-id: uint, photo-id: uint }
    {
        added-by: principal,
        photo-hash: (string-ascii 64),
        description: (string-ascii 256),
        likes: uint,
        created-at: uint
    }
)

(define-map album-collaborators
    { album-id: uint, user: principal }
    { can-add: bool, can-remove: bool }
)

(define-map photo-likes
    { photo-id: uint, user: principal }
    { liked-at: uint }
)

;; Data Variables
(define-data-var last-album-id uint u0)
(define-data-var last-photo-id uint u0)

;; Private Functions
(define-private (is-album-collaborator (album-id uint) (user principal))
    (default-to 
        false
        (get can-add (map-get? album-collaborators {album-id: album-id, user: user}))
    )
)

(define-private (is-album-owner (album-id uint))
    (let (
        (album (unwrap! (map-get? albums {album-id: album-id}) false))
    )
        (is-eq (get owner album) tx-sender)
    )
)

;; Public Functions
(define-public (create-album (name (string-ascii 64)) (description (string-ascii 256)) (is-public bool))
    (let (
        (new-album-id (+ (var-get last-album-id) u1))
    )
        (map-set albums
            {album-id: new-album-id}
            {
                owner: tx-sender,
                name: name,
                description: description,
                is-public: is-public,
                created-at: block-height
            }
        )
        (var-set last-album-id new-album-id)
        (ok new-album-id)
    )
)

(define-public (add-photo 
    (album-id uint) 
    (photo-hash (string-ascii 64)) 
    (description (string-ascii 256)))
    (let (
        (album (unwrap! (map-get? albums {album-id: album-id}) ERR_ALBUM_NOT_FOUND))
        (new-photo-id (+ (var-get last-photo-id) u1))
    )
        (asserts! 
            (or 
                (is-album-owner album-id)
                (is-album-collaborator album-id tx-sender)
            )
            ERR_NOT_AUTHORIZED
        )
        (map-set photos
            {album-id: album-id, photo-id: new-photo-id}
            {
                added-by: tx-sender,
                photo-hash: photo-hash,
                description: description,
                likes: u0,
                created-at: block-height
            }
        )
        (var-set last-photo-id new-photo-id)
        (ok new-photo-id)
    )
)

(define-public (add-collaborator (album-id uint) (collaborator principal) (can-add bool) (can-remove bool))
    (begin
        (asserts! (is-album-owner album-id) ERR_NOT_AUTHORIZED)
        (ok (map-set album-collaborators
            {album-id: album-id, user: collaborator}
            {can-add: can-add, can-remove: can-remove}
        ))
    )
)

(define-public (like-photo (album-id uint) (photo-id uint))
    (let (
        (photo (unwrap! (map-get? photos {album-id: album-id, photo-id: photo-id}) ERR_PHOTO_NOT_FOUND))
    )
        (map-set photo-likes
            {photo-id: photo-id, user: tx-sender}
            {liked-at: block-height}
        )
        (map-set photos
            {album-id: album-id, photo-id: photo-id}
            (merge photo {likes: (+ (get likes photo) u1)})
        )
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-album (album-id uint))
    (ok (unwrap! (map-get? albums {album-id: album-id}) ERR_ALBUM_NOT_FOUND))
)

(define-read-only (get-photo (album-id uint) (photo-id uint))
    (ok (unwrap! (map-get? photos {album-id: album-id, photo-id: photo-id}) ERR_PHOTO_NOT_FOUND))
)