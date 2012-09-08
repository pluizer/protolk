
(cond-expand
 ((not protolk-all-tests)
  (load-relative "helpers")
  (load-relative "../protolk-primitives")
  (import protolk
          protolk-primitives
          protolk-internal))
 (else))


;;; Unhygienic because parts of the expansion will be displayed in
;;; error messages, etc.
(define-syntax describe-pob-slot
  (er-macro-transformer
   (lambda (exp rename compare)
     (let* ((make-pob-exp '(%make-pob 0 1 2 3 4))
            (slotnum  (list-ref exp 1))
            (slotname (list-ref exp 2))
            (getter   (list-ref exp 3))
            (setter   (list-ref exp 4)))
       `(begin
          
          (describe ,(sprintf "~a" getter)
            (it ,(sprintf "returns the pob's ~a slot value" slotname)
              (equal? (,getter ,make-pob-exp)
                      ,slotnum))
            (it "fails when given a non-pob"
              (raises? ()
                (,getter 'notapob)))
            (it "fails when given no args"
              (raises? ()
                (,getter))))

          (describe ,(sprintf "~a" setter)
            (it ,(sprintf "modifies the pob's ~a slot value" slotname)
              (let ((pob ,make-pob-exp))
                (,setter pob 'new-slot-value)
                (equal? (,getter pob) 'new-slot-value)))
            (it "fails when given a non-pob"
              (raises? ()
                (,setter 'notapob 'new-slot-value)))
            (it "fails when given no args"
              (raises? ()
                (,setter)))
            (it "fails when given only one arg"
              (let ((pob ,make-pob-exp))
                (raises? ()
                  (,setter pob))))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; POB PRITIMIVE RECORD TYPE
;;

(describe "pob pritimive record type"

  (describe "%make-pob"
    (it "succeeds when given a base, props, methods, resolve-prop, and resolve-method"
      (not (raises? ()
             (%make-pob #f '() '() #f #f))))
    (it "fails when given no args"
      (raises? ()
        (%make-pob)))
    (it "fails when given only one arg"
      (raises? ()
        (%make-pob #f)))
    (it "fails when given only two args"
      (raises? ()
        (%make-pob #f '())))
    (it "fails when given only three args"
      (raises? ()
        (%make-pob #f '() '())))
    (it "fails when given only four args"
      (raises? ()
        (%make-pob #f '() '() #f)))
    (it "fails when given six or more args"
      (raises? ()
        (%make-pob #f '() '() #f #f #f))))


  (describe "pob?"
    (it "returns #t when given a pob"
      (pob? (%make-pob #f '() '() #f #f)))
    (it "returns #f when given a non-pob"
      (not (pob? 'notapob)))
    (it "fails when given no args"
      (raises? ()
        (pob?))))


  (describe-pob-slot 0 "base"    %pob-base    %pob-set-base!)
  (describe-pob-slot 1 "props"   %pob-props   %pob-set-props!)
  (describe-pob-slot 2 "methods" %pob-methods %pob-set-methods!)
  (describe-pob-slot 3 "resolve-prop"
                     %pob-resolve-prop
                     %pob-set-resolve-prop!)
  (describe-pob-slot 4 "resolve-method"
                     %pob-resolve-method
                     %pob-set-resolve-method!))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIMITIVE PROP ACCESSORS
;;

(describe "primitive prop accessors"

  (describe "%has-prop?"
    (it "returns #t when the pob has a matching prop"
      (%has-prop? (%make-pob #f '((a . 1)) '() #f #f) 'a))
    (it "returns #f when the pob does not have a matching prop"
      (not (%has-prop? (%make-pob #f '((a . 1)) '() #f #f) 'foo)))
    (it "fails when given a non-pob"
      (raises? ()
        (%has-prop? 'foo 'a)))
    (it "fails when no prop name is specified"
      (raises? ()
        (%has-prop? (%make-pob #f '((a . 1)) '() #f #f)))))

  (describe "%prop"
    (it "returns the value of a matching prop"
      (equal? (%prop (%make-pob #f '((a . 1)) '() #f #f) 'a)
              1))
    (it "returns #<unspecified> when there is no matching prop"
      (equal? (%prop (%make-pob #f '((a . 1)) '() #f #f) 'foo)
              (void)))
    (it "optionally accepts a default return value"
      (equal? (%prop (%make-pob #f '((a . 1)) '() #f #f) 'foo 'result)
              'result))
    (it "fails when given a non-pob"
      (raises? ()
        (%prop 'foo 'bar)))
    (it "fails when no prop name is specified"
      (raises? ()
        (%prop (%make-pob #f '((a . 1)) '() #f #f)))))

  (describe "%set-prop!"
    (it "sets the specified prop in the pob"
      (let ((pob (%make-pob #f '() '() #f #f)))
        (%set-prop! pob 'a 1)
        (equal? (%prop pob 'a) 1)))
    (it "replaces the value of existing props with that name"
      (let ((pob (%make-pob #f '((a . 1)) '() #f #f)))
        (%set-prop! pob 'a 2)
        (equal? (%prop pob 'a) 2)))
    (it "fails when given no args"
      (raises? ()
        (%set-prop!)))
    (it "fails when given a non-pob"
      (raises? ()
        (%set-prop! 'foo 'a 1)))
    (it "fails when no prop name or value is specified"
      (raises? ()
        (%set-prop! (%make-pob #f '() '() #f #f))))
    (it "fails when no value is specified"
      (raises? ()
        (%set-prop (%make-pob #f '() '() #f #f) 'a))))

  (describe "%unset-prop!"
    (it "removes all matching props from the pob"
      (let ((pob (%make-pob #f '((a . 2) (a . 1)) '() #f #f)))
        (%unset-prop! pob 'a)
        (not (%has-prop? pob 'a))))
    (it "has no effect if there are no matching props"
      (let ((pob (%make-pob #f '() '() #f #f)))
        (%unset-prop! pob 'a)
        (not (%has-prop? pob 'a))))
    (it "fails when given no args"
      (raises? ()
        (%unset-prop!)))
    (it "fails when given a non-pob"
      (raises? ()
        (%unset-prop! 'foo 'a)))
    (it "fails when no prop name is specified"
      (raises? ()
        (%unset-prop! (%make-pob #f '() '() #f #f))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIMITIVE METHOD ACCESSORS
;;

(describe "primitive method accessors"
  (define (fn pob) #t)
  (define (fn2 pob) #f)

  (describe "%has-method?"
    (it "returns #t when the pob has a matching method"
      (%has-method? (%make-pob #f '() `((m . ,fn)) #f #f) 'm))
    (it "returns #f when the pob does not have a matching method"
      (not (%has-method? (%make-pob #f '() `((m . ,fn)) #f #f) 'foo)))
    (it "fails when given a non-pob"
      (raises? ()
        (%has-method? 'foo 'm)))
    (it "fails when no method name is specified"
      (raises? ()
        (%has-method? (%make-pob #f '() `((m . ,fn)) #f #f)))))

  (describe "%method"
    (it "returns the value of a matching method"
      (equal? (%method (%make-pob #f '() `((m . ,fn)) #f #f) 'm)
              fn))
    (it "returns #<unspecified> when there is no matching method"
      (equal? (%method (%make-pob #f '() `((m . ,fn)) #f #f) 'foo)
              (void)))
    (it "optionally accepts a default return value"
      (equal? (%method (%make-pob #f '() `((m . ,fn)) #f #f) 'foo fn)
              fn))
    (it "fails when given a non-pob"
      (raises? ()
        (%method 'foo 'm)))
    (it "fails when no method name is specified"
      (raises? ()
        (%method (%make-pob #f '() `((m . ,fn)) #f #f)))))

  (describe "%set-method!"
    (it "sets the specified method in the pob"
      (let ((pob (%make-pob #f '() '() #f #f)))
        (%set-method! pob 'm fn)
        (equal? (%method pob 'm) fn)))
    (it "replaces the value of existing methods with that name"
      (let ((pob (%make-pob #f '() `((m . ,fn)) #f #f)))
        (%set-method! pob 'm fn)
        (equal? (%method pob 'm) fn)))
    (it "fails when given no args"
      (raises? ()
        (%set-method!)))
    (it "fails when given a non-pob"
      (raises? ()
        (%set-method! 'foo 'm fn)))
    (it "fails when no method name or value is specified"
      (raises? ()
        (%set-method! (%make-pob #f '() '() #f #f))))
    (it "fails when no value is specified"
      (raises? ()
        (%set-method (%make-pob #f '() '() #f #f) 'fn))))

  (describe "%unset-method!"
    (it "removes all matching methods from the pob"
      (let ((pob (%make-pob #f '() `((m . fn2) (m . fn)) #f #f)))
        (%unset-method! pob 'm)
        (not (%has-method? pob 'm))))
    (it "has no effect if there are no matching methods"
      (let ((pob (%make-pob #f '() '() #f #f)))
        (not (%has-method? pob 'm))))
    (it "fails when given no args"
      (raises? ()
        (%unset-method!)))
    (it "fails when given a non-pob"
      (raises? ()
        (%unset-method! 'foo 'a)))
    (it "fails when no method name is specified"
      (raises? ()
        (%unset-method! (%make-pob #f '() '() #f #f))))))



(cond-expand
 ((not protolk-all-tests)
  (test-exit))
 (else))
