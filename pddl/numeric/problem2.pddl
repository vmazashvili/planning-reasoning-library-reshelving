(define (problem library-p2-numeric)
  (:domain library-reshelving-numeric)

  (:objects
    r1 r2                                                    - robot
    b1 b2 b3 b4                                              - book
    cart z1 z2 fiction_shelf science_shelf history_shelf z3  - zone
    c_fiction c_science c_history                            - category
  )

  (:init
    ;; robot states
    (robot-at r1 cart)
    (robot-at r2 cart)
    (free r1)
    (free r2)
    (= (battery r1) 100)
    (= (battery r2) 100)

    ;; book positions
    (book-at b1 cart)
    (book-at b2 cart)
    (book-at b3 cart)
    (book-at b4 cart)

    ;; book categories
    (book-category b1 c_fiction)
    (book-category b2 c_fiction)
    (book-category b3 c_science)
    (book-category b4 c_history)

    ;; shelf categories
    (shelf-category fiction_shelf c_fiction)
    (shelf-category science_shelf c_science)
    (shelf-category history_shelf c_history)

    ;; charging dock
    (station-at z3)

    ;; paths (branching, symmetric)
    (path cart z1)                  (path z1 cart)
    (path z1 fiction_shelf)         (path fiction_shelf z1)
    (path z1 z2)                    (path z2 z1)
    (path z2 science_shelf)         (path science_shelf z2)
    (path z1 history_shelf)         (path history_shelf z1)
    (path history_shelf z3)         (path z3 history_shelf)

    ;; cost accumulator
    (= (total-cost) 0)
  )

  (:goal (and
    (shelved b1)
    (shelved b2)
    (shelved b3)
    (shelved b4)
  ))

  (:metric minimize (total-cost))
)
