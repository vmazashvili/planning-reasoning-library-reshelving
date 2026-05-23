(define (problem library-p1)
  (:domain library-reshelving)

  (:objects
    r1                    - robot
    b1 b2                 - book
    cart z1 fiction_shelf z2 science_shelf  - zone
    c_fiction c_science   - category
  )

  (:init
    ; --- robot state ---
    (robot-at r1 cart)
    (free r1)
    ; battery is full at start (no battery-low fact)

    ; --- book positions ---
    (book-at b1 cart)
    (book-at b2 cart)

    ; --- book categories ---
    (book-category b1 c_fiction)
    (book-category b2 c_science)

    ; --- shelf categories ---
    (shelf-category fiction_shelf c_fiction)
    (shelf-category science_shelf c_science)

    ; --- charging dock ---
    (station-at z1)

    ; --- paths (symmetric: encode both directions) ---
    (path cart z1)            (path z1 cart)
    (path z1 fiction_shelf)   (path fiction_shelf z1)
    (path fiction_shelf z2)   (path z2 fiction_shelf)
    (path z2 science_shelf)   (path science_shelf z2)
  )

  (:goal (and
    (shelved b1)
    (shelved b2)
  ))
)
