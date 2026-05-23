(define (domain library-reshelving)
;not using :adl, :conditional-effects, :existential-preconditions, or
;:disjunctive-preconditions to keep the project
;compatible with all four heuristics: h^max, h^add, h^FF, blind
(:requirements :strips :typing :negative-preconditions)

    (:types
        robot book zone category - object
    )

    (:predicates
        ; --- fluents (change over time) ---
        (robot-at ?r - robot ?z - zone)
        (book-at ?b - book ?z - zone)
        (carrying ?r - robot ?b - book)
        (shelved ?b - book)
        (battery-low ?r - robot)
        (free ?r - robot)                ; true when robot holds nothing

        ; --- rigid (set once in problem, never change) ---
        (path ?z1 - zone ?z2 - zone)
        (station-at ?z - zone)
        (book-category ?b - book ?c - category)
        (shelf-category ?z - zone ?c - category)
    )

    (:action navigate
        :parameters (?r - robot ?z1 - zone ?z2 - zone)
        :precondition (and
            (robot-at ?r ?z1)
            (path ?z1 ?z2)
        )
        :effect (and
            (robot-at ?r ?z2)
            (not (robot-at ?r ?z1))
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
            (not (battery-low ?r))
        )
        :effect (and
            (shelved ?b)
            (book-at ?b ?z)
            (not (carrying ?r ?b))
            (free ?r)
            (battery-low ?r)
        )
    )

    (:action recharge
        :parameters (?r - robot ?z - zone)
        :precondition (and
            (robot-at ?r ?z)
            (station-at ?z)
            (battery-low ?r)
        )
        :effect (and
            (not (battery-low ?r))
        )
    )
)
