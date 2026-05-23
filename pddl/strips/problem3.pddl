(define (problem library-p3)
  (:domain library-reshelving)

  (:objects
    r1 r2                                                  - robot
    b1 b2 b3 b4 b5 b6                                      - book
    cart
    z1 z2 z3 z4 z5
    fiction_shelf science_shelf history_shelf biology_shelf
    dock1 dock2                                            - zone
    c_fiction c_science c_history c_biology                - category
  )

  (:init
    ; --- robot states ---
    (robot-at r1 cart)
    (robot-at r2 cart)
    (free r1)
    (free r2)
    ; both batteries full

    ; --- book positions (all at cart) ---
    (book-at b1 cart)
    (book-at b2 cart)
    (book-at b3 cart)
    (book-at b4 cart)
    (book-at b5 cart)
    (book-at b6 cart)

    ; --- book categories (mix: 2 fiction, 2 science, 1 history, 1 biology) ---
    (book-category b1 c_fiction)
    (book-category b2 c_fiction)
    (book-category b3 c_science)
    (book-category b4 c_science)
    (book-category b5 c_history)
    (book-category b6 c_biology)

    ; --- shelf categories ---
    (shelf-category fiction_shelf c_fiction)
    (shelf-category science_shelf c_science)
    (shelf-category history_shelf c_history)
    (shelf-category biology_shelf c_biology)

    ; --- 2 charging docks ---
    (station-at dock1)
    (station-at dock2)

    ; --- paths (grid topology, all symmetric) ---
    ; Row 1 (top): fiction --- z1 --- science --- z3
    (path fiction_shelf z1)         (path z1 fiction_shelf)
    (path z1 science_shelf)         (path science_shelf z1)
    (path science_shelf z3)         (path z3 science_shelf)

    ; Row 2 (middle): z4 --- dock1 --- z5 --- biology
    (path z4 dock1)                 (path dock1 z4)
    (path dock1 z5)                 (path z5 dock1)
    (path z5 biology_shelf)         (path biology_shelf z5)

    ; Row 3 (bottom): cart --- z2 --- history --- dock2
    (path cart z2)                  (path z2 cart)
    (path z2 history_shelf)         (path history_shelf z2)
    (path history_shelf dock2)      (path dock2 history_shelf)

    ; Vertical connectors
    (path fiction_shelf z4)         (path z4 fiction_shelf)
    (path z4 cart)                  (path cart z4)
    (path z1 dock1)                 (path dock1 z1)
    (path dock1 z2)                 (path z2 dock1)
    (path science_shelf z5)         (path z5 science_shelf)
    (path z5 history_shelf)         (path history_shelf z5)
    (path z3 biology_shelf)         (path biology_shelf z3)
  )

  (:goal (and
    (shelved b1)
    (shelved b2)
    (shelved b3)
    (shelved b4)
    (shelved b5)
    (shelved b6)
  ))
)
