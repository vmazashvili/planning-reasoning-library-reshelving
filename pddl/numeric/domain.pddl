(define (domain library-reshelving-numeric)
;; Numeric variant of the STRIPS library-reshelving domain.
;; Battery is modelled as a numeric fluent rather than a Boolean.
;; Action costs are unit by default but vary per action type.

  (:requirements :strips :typing :negative-preconditions :numeric-fluents :action-costs)

  (:types
    robot book zone category - object
  )

  (:predicates
    ;; fluents (change over time)
    (robot-at ?r - robot ?z - zone)
    (book-at ?b - book ?z - zone)
    (carrying ?r - robot ?b - book)
    (shelved ?b - book)
    (free ?r - robot)

    ;; rigid
    (path ?z1 - zone ?z2 - zone)
    (station-at ?z - zone)
    (book-category ?b - book ?c - category)
    (shelf-category ?z - zone ?c - category)
  )

  (:functions
    (battery ?r - robot)   ; 0..100
    (total-cost)           ; action-cost accumulator
  )

  (:action navigate
    :parameters (?r - robot ?z1 - zone ?z2 - zone)
    :precondition (and
      (robot-at ?r ?z1)
      (path ?z1 ?z2)
      (>= (battery ?r) 10)
    )
    :effect (and
      (robot-at ?r ?z2)
      (not (robot-at ?r ?z1))
      (decrease (battery ?r) 10)
      (increase (total-cost) 1)
    )
  )

  (:action pickup
    :parameters (?r - robot ?b - book ?z - zone)
    :precondition (and
      (robot-at ?r ?z)
      (book-at ?b ?z)
      (free ?r)
      (not (shelved ?b))
    )
    :effect (and
      (carrying ?r ?b)
      (not (free ?r))
      (not (book-at ?b ?z))
    )
  )

  (:action shelve
    :parameters (?r - robot ?b - book ?z - zone ?c - category)
    :precondition (and
      (robot-at ?r ?z)
      (carrying ?r ?b)
      (shelf-category ?z ?c)
      (book-category ?b ?c)
      (>= (battery ?r) 30)
    )
    :effect (and
      (shelved ?b)
      (book-at ?b ?z)
      (not (carrying ?r ?b))
      (free ?r)
      (decrease (battery ?r) 30)
      (increase (total-cost) 2)
    )
  )

  (:action recharge
    :parameters (?r - robot ?z - zone)
    :precondition (and
      (robot-at ?r ?z)
      (station-at ?z)
      (< (battery ?r) 100)
    )
    :effect (and
      (assign (battery ?r) 100)
      (increase (total-cost) 3)
    )
  )
)
