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

;; Data Maps
;; [Previous maps remain unchanged]

;; Events
(define-data-var last-event-id uint u0)

(define-map events 
    { event-id: uint }
    {
        event-type: (string-ascii 24),
        subject-id: uint,
        actor: principal,
        timestamp: uint
    }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 24)) (subject-id uint))
    (let ((new-event-id (+ (var-get last-event-id) u1)))
        (map-set events
            { event-id: new-event-id }
            {
                event-type: event-type,
                subject-id: subject-id,
                actor: tx-sender,
                timestamp: block-height
            }
        )
        (var-set last-event-id new-event-id)
        new-event-id
    )
)

;; [Previous private functions remain unchanged]

;; Public Functions
(define-public (delete-photo (album-id uint) (photo-id uint))
    (let (
        (photo (unwrap! (map-get? photos {album-id: album-id, photo-id: photo-id}) ERR_PHOTO_NOT_FOUND))
    )
        (asserts! 
            (or 
                (is-album-owner album-id)
                (is-album-collaborator album-id tx-sender)
            )
            ERR_NOT_AUTHORIZED
        )
        (map-delete photos {album-id: album-id, photo-id: photo-id})
        (emit-event "photo_deleted" photo-id)
        (ok true)
    )
)

;; Enhanced like-photo with duplicate prevention
(define-public (like-photo (album-id uint) (photo-id uint))
    (let (
        (photo (unwrap! (map-get? photos {album-id: album-id, photo-id: photo-id}) ERR_PHOTO_NOT_FOUND))
        (existing-like (map-get? photo-likes {photo-id: photo-id, user: tx-sender}))
    )
        (asserts! (is-none existing-like) ERR_ALREADY_LIKED)
        (map-set photo-likes
            {photo-id: photo-id, user: tx-sender}
            {liked-at: block-height}
        )
        (map-set photos
            {album-id: album-id, photo-id: photo-id}
            (merge photo {likes: (+ (get likes photo) u1)})
        )
        (emit-event "photo_liked" photo-id)
        (ok true)
    )
)

;; Enhanced add-tag with coordinate validation
(define-public (add-tag (album-id uint) (photo-id uint) (tagged-user principal) (x uint) (y uint))
    (let (
        (photo (unwrap! (map-get? photos {album-id: album-id, photo-id: photo-id}) ERR_PHOTO_NOT_FOUND))
        (new-tag-id (+ (var-get last-tag-id) u1))
    )
        (asserts! (< x u1000) ERR_INVALID_COORDINATES) ;; Assuming max width 1000
        (asserts! (< y u1000) ERR_INVALID_COORDINATES) ;; Assuming max height 1000
        
        (map-set photo-tags
            {photo-id: photo-id, tag-id: new-tag-id}
            {
                tagged-user: tagged-user,
                tagged-by: tx-sender,
                x-coord: x,
                y-coord: y,
                created-at: block-height
            }
        )
        (map-set photos
            {album-id: album-id, photo-id: photo-id}
            (merge photo {tag-count: (+ (get tag-count photo) u1)})
        )
        (var-set last-tag-id new-tag-id)
        (emit-event "photo_tagged" photo-id)
        (ok new-tag-id)
    )
)

;; Enhanced read functions with proper pagination
(define-read-only (get-photo-comments (photo-id uint) (offset uint) (limit uint))
    (let ((comments (list)))
        (ok (filter 
            not-none 
            (map 
                (lambda (id) (map-get? photo-comments {photo-id: photo-id, comment-id: id}))
                (sequence offset (+ offset limit))
            )
        ))
    )
)

;; [Remaining functions unchanged]
