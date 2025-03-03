;; FrameTide Photo Album Contract

;; Constants 
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALBUM_NOT_FOUND (err u101))
(define-constant ERR_PHOTO_NOT_FOUND (err u102))
(define-constant ERR_INVALID_ALBUM (err u103))
(define-constant ERR_COMMENT_NOT_FOUND (err u104))
(define-constant ERR_TAG_NOT_FOUND (err u105))
(define-constant ERR_ALREADY_LIKED (err u106))
(define-constant ERR_INVALID_COORDINATES (err u107))
(define-constant ERR_RATE_LIMIT_EXCEEDED (err u108))
(define-constant ERR_MAX_ITEMS_EXCEEDED (err u109))
(define-constant ERR_INVALID_HASH (err u110))

;; Configuration Constants
(define-constant MAX_COMMENTS_PER_PHOTO u100)
(define-constant MAX_TAGS_PER_PHOTO u50)
(define-constant RATE_LIMIT_BLOCKS u10)
(define-constant MAX_BATCH_SIZE u20)

;; Data Maps
;; [Previous maps remain unchanged]

;; Rate Limiting Map
(define-map user-action-timestamps
    { user: principal, action-type: (string-ascii 12) }
    { last-action: uint }
)

;; Events with Enhanced Metadata
(define-data-var last-event-id uint u0)

(define-map events 
    { event-id: uint }
    {
        event-type: (string-ascii 24),
        subject-id: uint,
        actor: principal,
        timestamp: uint,
        metadata: (optional (string-ascii 256))
    }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 24)) (subject-id uint) (metadata (optional (string-ascii 256))))
    (let ((new-event-id (+ (var-get last-event-id) u1)))
        (map-set events
            { event-id: new-event-id }
            {
                event-type: event-type,
                subject-id: subject-id,
                actor: tx-sender,
                timestamp: block-height,
                metadata: metadata
            }
        )
        (var-set last-event-id new-event-id)
        new-event-id
    )
)

(define-private (check-rate-limit (action-type (string-ascii 12)))
    (let (
        (last-timestamp (default-to u0 (get last-action (map-get? user-action-timestamps { user: tx-sender, action-type: action-type }))))
    )
        (asserts! (> block-height (+ last-timestamp RATE_LIMIT_BLOCKS)) ERR_RATE_LIMIT_EXCEEDED)
        (map-set user-action-timestamps
            { user: tx-sender, action-type: action-type }
            { last-action: block-height }
        )
        true
    )
)

(define-private (validate-photo-hash (hash (string-ascii 64)))
    (asserts! (is-eq (len hash) u46) ERR_INVALID_HASH)  ;; Basic IPFS hash validation
    true
)

;; Enhanced Public Functions
(define-public (add-photo (album-id uint) (photo-hash (string-ascii 64)) (description (string-ascii 256)))
    (let (
        (album (unwrap! (map-get? albums {album-id: album-id}) ERR_ALBUM_NOT_FOUND))
    )
        (asserts! (validate-photo-hash photo-hash) ERR_INVALID_HASH)
        (asserts! (check-rate-limit "add_photo") true)
        ;; [Rest of the function remains the same]
    )
)

(define-public (batch-add-photos (album-id uint) (photo-data (list 20 {hash: (string-ascii 64), description: (string-ascii 256)})))
    (let (
        (album (unwrap! (map-get? albums {album-id: album-id}) ERR_ALBUM_NOT_FOUND))
    )
        (asserts! (<= (len photo-data) MAX_BATCH_SIZE) ERR_MAX_ITEMS_EXCEEDED)
        (asserts! (check-rate-limit "batch_add") true)
        ;; Implementation of batch photo addition
        (ok true)
    )
)

;; [Previous functions with rate limiting and validation added]

;; Enhanced read functions with efficient pagination
(define-read-only (get-photo-comments (photo-id uint) (offset uint) (limit uint))
    (let (
        (max-comment-id (default-to u0 (get comment-count (map-get? photos {photo-id: photo-id}))))
        (adjusted-limit (if (> limit u50) u50 limit))
    )
        (ok (filter 
            not-none 
            (map 
                (lambda (id) (map-get? photo-comments {photo-id: photo-id, comment-id: id}))
                (sequence 
                    (if (> offset max-comment-id) max-comment-id offset)
                    (min max-comment-id (+ offset adjusted-limit))
                )
            )
        ))
    )
)
