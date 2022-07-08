(load-relative "loadtest.rktl")

(Section 'function)

(require racket/function)

;; stuff from racket/base

(let ([C #f])
  (define-syntax-rule (def-both [name* name] ...)
    (begin (define-syntax-rule (name* x (... ...))
             (begin (set! C compose1) (name x (... ...))
                    (set! C compose)  (name x (... ...))
                    (set! C #f)))
           ...))
  (def-both [test* test] [err/rt-test* err/rt-test] [test-values* test-values])
  ;; Simple cases
  (test* values C)
  (test* car C car)
  (test* sin C sin)
  (err/rt-test* (C 1))
  ;; Binary cases
  (test* 123 (C add1 sub1) 123)
  (test* 'values object-name (C))
  (test* '+ object-name (compose + values values))
  (test* '+ object-name (compose values + values values))
  (test* '+ object-name (C values values + values))
  (test* '+ object-name (C values values values +))
  (test* 'composed object-name (C - values values + values))
  (test* 'composed object-name (C + values - + values))
  (test* 'composed object-name (C add1 sub1))
  (define (f:1/2 x [y 1]) (+ (* 10 x) y))
  (test* 52 (C add1 f:1/2) 5)
  (test* 16 (C add1 f:1/2) 1 5)
  (test 21 (compose f:1/2 quotient/remainder) 7 3)
  (let ([foo (compose1 f:1/2 quotient/remainder)]) (err/rt-test (foo 7 3)))
  (test* 61 (C f:1/2 +) 1 2 3)
  (define (f:kwd x #:y y #:z [z 0]) (list x y z))
  (test* '((1 2 3)) (C list f:kwd) 1 #:z 3 #:y 2)
  (test* '((1 2 0)) (C list f:kwd) 1 #:y 2)
  (err/rt-test* ((C list f:kwd) 1))
  (err/rt-test* (C 1 +))
  (err/rt-test* (C + 1))
  (err/rt-test* (C (lambda (#:x x) x) values))
  (err/rt-test* (C (lambda (#:x x) x) +))
  (err/rt-test* (C (lambda (x #:y y) x) +))
  (test* 3 (C length list) 1 2 3)
  (test* 2 (C length list) 1 2)
  (test* 1 (C length list) 1)
  (test* 0 (C length list))
  (err/rt-test (compose1 (lambda (x y) x) +))
  (let ([foo (compose (lambda (x y) x) +)]) ; no error here...
    (err/rt-test (foo 1)))                  ; ...only when running it
  ;; More than two
  (err/rt-test* (C 1 add1 add1))
  (err/rt-test* (C add1 1 add1))
  (err/rt-test* (C add1 add1 1))
  (test* 4 (C add1 add1 add1) 1)
  (test* 4 (C + add1 add1 add1) 1)
  (test* 4 (C add1 + add1 add1) 1)
  (test* 4 (C add1 add1 + add1) 1)
  (test* 4 (C add1 add1 add1 +) 1)
  (test* 9 (C add1 add1 add1 +) 1 2 3)
  (err/rt-test* (C add1 (lambda (x #:y y) x) add1 add1))
  (err/rt-test (compose1 add1 (lambda (x y) x) add1 add1))
  (test #t procedure? (compose add1 (lambda (x y) x) add1 add1))
  (define (+-1 x) (values (add1 x) (sub1 x)))
  (test* #t procedure? (C list +-1 car list add1))
  (test '(7 5) (compose list +-1 car list add1) 5)
  (err/rt-test ((compose1 list +-1 car list add1) 5))
  (test* 10 (C car list sub1 car list add1) 10)                ; fwd pipeline
  (test* 10 (C car list sub1 car list (lambda (x) x) add1) 10) ; rev pipeline
  ;; any input arity on the RHS
  (test* 4        (C add1 add1 add1 (lambda () 1)))
  (test* 3        (C add1 add1 (lambda () 1)))
  (test* 2        (C add1 (lambda () 1)))
  (test* 1        (C (lambda () 1)))
  (test* '(1 2 3) (C car list list) 1 2 3)
  (test* '(1 2)   (C car list list) 1 2)
  (test* '(1)     (C car list list) 1)
  (test* '()      (C car list list))
  (test* '(1 2 3) (C car list f:kwd) 1 #:z 3 #:y 2)
  (test* '(1 2 0) (C car list f:kwd) 1 #:y 2)
  ;; any output arity on the LHS
  (test-values* '(2 0) (lambda () ((C +-1 add1) 0)))
  (test-values* '(3 1) (lambda () ((C +-1 add1 add1) 0)))
  (test-values* '() (lambda () ((C (lambda (_) (values)) add1) 0)))
  (test-values* '() (lambda () ((C (lambda (_) (values)) add1 add1) 0)))
  ;; `compose1` tests
  (test* 'values object-name (compose1 values values))
  (test* 'values object-name (compose1 values values values))
  (test* '+ object-name (compose1 values +))
  (test* '+ object-name (compose1 + values))
  (test* '+ object-name (compose1 values values +))
  (test* '+ object-name (compose1 values + values))
  #;(test* '+ object-name (compose1 + values values))
  (test* 'add1 object-name (compose1 values add1))
  (test* 'add1 object-name (compose1 add1 values))
  (test* 'add1 object-name (compose1 values values add1))
  (test* 'add1 object-name (compose1 values add1 values))
  #;(test* 'add1 object-name (compose1 add1 values values))
  (test* #f (lambda (f) (eq? values f)) (compose1 values values))
  (test* #f (lambda (f) (eq? values f)) (compose1 values values values))
  (test* #t (lambda (f) (eq? + f)) (compose1 values +))
  (test* #f (lambda (f) (eq? + f)) (compose1 + values))
  (test* #f (lambda (f) (eq? + f)) (compose1 + values values))
  (test* #f (lambda (f) (eq? + f)) (compose1 values + values))
  (test* #t (lambda (f) (eq? + f)) (compose1 values values +))
  (test* #t (lambda (f) (eq? add1 f)) (compose1 values add1))
  (test* #t (lambda (f) (eq? add1 f)) (compose1 add1 values))
  (test* #f (lambda (f) (eq? add1 f)) (compose1 add1 values values))
  (test* #t (lambda (f) (eq? add1 f)) (compose1 values add1 values))
  (test* #t (lambda (f) (eq? add1 f)) (compose1 values values add1))
  (err/rt-test* ((compose1 + values) 1 2))
  (err/rt-test* ((compose1 values values) 1 2))
  (err/rt-test* ((compose1 values values values) 1 2))
  (err/rt-test* ((compose1 values + values) 1 2))
  (err/rt-test* ((compose1 + values values) 1 2))
  ;; some older `compose' tests (a bit extended)
  (test -1 (compose (lambda (a b) (+ a b))
                    (lambda (x y) (values (- y) x)))
        2 3)
  (test -1 (compose (lambda (a b) (+ a b))
                    (lambda (x y) (values (- y) x))
                    (lambda (x y) (values x y)))
        2 3)
  (test -1 (compose (lambda (a b) (+ a b))
                    (lambda (x y) (values (- y) x))
                    values)
        2 3)
  (test -1 (compose (lambda (a b) (+ a b))
                    values
                    (lambda (x y) (values (- y) x))
                    values)
        2 3)
  (test 'hi (compose (case-lambda [(x) 'bye] [(y z) 'hi])
                     (lambda () (values 1 2))))
  (test 'hi (compose (case-lambda [(x) 'bye] [(y z) 'hi])
                     values
                     (lambda () (values 1 2))))
  (err/rt-test* ((C add1 (lambda () (values 1 2)))) exn:fail:contract:arity?)
  (err/rt-test* ((C add1 sub1)) exn:fail:contract:arity?)
  (err/rt-test ((compose (lambda () 1) add1) 8) exn:fail:contract:arity?)
  (arity-test compose1 0 -1)
  (arity-test compose  0 -1))

;; ---------- procedure-result-arity ----------

(test 1 procedure-result-arity car)
(test 1 procedure-result-arity list)
(test 1 procedure-result-arity (procedure-reduce-arity car 1))
(let ([adjust-no-information (lambda (x)
                               ;; `(arity-at-least 0)` is the same as `#f`,
                               ;; since both are no information
                               (or x (arity-at-least 0)))])
  (test (arity-at-least 0) adjust-no-information (procedure-result-arity values))
  (test (arity-at-least 0) adjust-no-information (procedure-result-arity (procedure-reduce-arity values 1)))
  (test (arity-at-least 0) adjust-no-information (procedure-result-arity call/cc)))
(let ()
  (struct s (x))
  (test 1 procedure-result-arity s-x)
  (test 1 procedure-result-arity s?)
  (test 1 procedure-result-arity s))
(test 1 procedure-result-arity (λ (x) 0))
(test 1 procedure-result-arity (let ([f 1]) (λ (x) (+ f x))))
(test #f procedure-result-arity
      (λ ()
        (if (= 0 (random 1))
            1
            (values 1 2))))
(test #f procedure-result-arity
      (procedure-reduce-arity
       (λ ()
         (if (= 0 (random 1))
             1
             (values 1 2)))
       0))
(err/rt-test (procedure-result-arity 1) exn:fail?)
(test 1 procedure-result-arity (chaperone-procedure car values))
(test 1 procedure-result-arity (impersonate-procedure car (λ (x) 1)))
(test #f procedure-result-arity (λ (x) (values x x)))
(test 1 procedure-result-arity (parameterize ([eval-jit-enabled #f])
                                 (eval '(λ (x) x))))
(test 1 procedure-result-arity (parameterize ([eval-jit-enabled #f])
                                 (eval '(case-lambda
                                          [(x) x]
                                          [(x y) x]
                                          [(a b c d e f) a]
                                          [(a b . whatever) a]))))
(test #f procedure-result-arity (parameterize ([eval-jit-enabled #f])
                                  (eval '(case-lambda
                                           [(x) x]
                                           [(x y) (values x y)]
                                           [(a b c d e f) (values 1 2 3 4 5 6 7 8)]
                                           [(a b . whatever) a]))))

(let ()
  (struct s (f) #:property prop:procedure 0)
  (test (case (system-type 'vm)
          ;; maybe this test will start failing at
          ;; some point and return 1 instead of #f
          [(racket) #f]
          [else 1])
        procedure-result-arity (s car)))

;; ---------- identity ----------
(let ()
  (test 'foo identity 'foo)
  (test 1 identity 1)
  (define x (gensym))
  (test x identity x)
  (err/rt-test (identity 1 2))
  (err/rt-test (identity)))

;; ---------- const ----------
(let ()
  (test 'foo (const 'foo))
  (test 'foo (const 'foo) 1)
  (test 'foo (const 'foo) 1 2 3 4 5))

;; ---------- thunk ----------
(let ([th1 (thunk 'foo)] [th2 (thunk* 'bar)])
  (test #t procedure? th1)
  (test #t procedure? th2)
  (test 0 procedure-arity th1)
  (test (arity-at-least 0) procedure-arity th2)
  (test 'foo th1)
  (err/rt-test (th1 1))
  (test 'bar th2)
  (test 'bar th2 1)
  (test 'bar th2 1 2 3)
  (test 'bar th2 1 #:x 2 3 #:y 4 5))

;; ---------- negate ----------
(let ()
  (define *not (negate not))
  (test #t *not #t)
  (test #f *not #f)
  (test #t *not 12)
  (define *void (negate void))
  (test #f *void)
  (define *< (negate <))
  (test #t *< 12 3)
  (test #t *< 12 12)
  (test #f *< 11 12)
  (test #t *< 14 13 12 11)
  (test #f *< 11 12 13 14)
  (define (bigger? n #:than [than 0]) (> n than))
  (define smaller? (negate bigger?))
  (test #t smaller? -5)
  (test #f smaller?  5)
  (test #t smaller?  5 #:than 10)
  (test #f smaller? 15 #:than 10)
  (test #t smaller? #:than 10  5)
  (test #f smaller? #:than 10 15))

;; ---------- curry/r ----------
(let ()
  (define foo0 (lambda () 0))
  (define foo1 (lambda (x) x))
  (define foo3 (lambda (x y z) (list x y z)))
  (define foo2< (lambda (x y . r) (list* x y r)))
  (define foo35 (case-lambda [(a b c) 3] [(a b c d e) 5]))
  (define foo:x (lambda (#:x [x 1] n . ns) (* x (apply + n ns))))
  (define *foo0  (curry foo0))
  (define *foo1  (curry foo1))
  (define *foo3  (curry foo3))
  (define *foo2< (curry foo2<))
  (define *foo35 (curry foo35))
  (define *foo:x2 (curry foo:x #:x 2))
  (define ++ (curry +))
  (define-syntax-rule ((f x ...) . => . e2) (test e2 f x ...))
  ;; see the docs for why these are expected
  (((curry foo0)) . => . 0)
  ((*foo0) . => . 0)
  ((curry foo1 123) . => . 123)
  ((*foo1 123) . => . 123)
  (((*foo1) 123) . => . 123)
  ((((*foo1)) 123) . => . 123)
  ((curry foo3 1 2 3) . => . '(1 2 3))
  ((*foo3 1 2 3) . => . '(1 2 3))
  (((*foo3 1 2) 3) . => . '(1 2 3))
  (((((((*foo3) 1)) 2)) 3) . => . '(1 2 3))
  (((curry foo2< 1 2)) . => . '(1 2))
  (((curry foo2< 1 2 3)) . => . '(1 2 3))
  (((curry foo2< 1 2) 3) . => . '(1 2 3))
  (((*foo2< 1 2)) . => . '(1 2))
  (((*foo2< 1 2 3)) . => . '(1 2 3))
  (((*foo2< 1 2) 3) . => . '(1 2 3))
  (((curry + 1 2) 3) . => . 6)
  (((++ 1 2) 3) . => . 6)
  (((++) 1 2) . => . 3)
  (((++)) . => . 0)
  (((curry foo35 1 2) 3) . => . 3)
  (((curry foo35 1 2 3)) . => . 3)
  (((*foo35 1 2) 3) . => . 3)
  (((*foo35 1 2 3)) . => . 3)
  (((((*foo35 1 2 3 4))) 5) . => . 5)
  (((((((((((*foo35)) 1)) 2)) 3 4))) 5) . => . 5)
  ((*foo:x2 1 2 3) . => . 12)
  ((map *foo:x2 '(1 2 3)) . => . '(2 4 6))
  ((((curryr foo3 1) 2) 3) . => . '(3 2 1))
  (((curryr list 1) 2 3) . => . '(2 3 1))
  )

;; Regression test for arity checking and a large number of arguments
;; (thanks to James Bornholt)
(let ()
  (define extreme
    (case-lambda
      [(op x) x]
      [(op x y) (if (op x y) x y)]
      [(op x y . z) (apply extreme op (extreme op x y) z)]))

  (define @max (curry extreme >=))

  (define l (for/list ([i 100]) 0))
  (test 0 apply @max l))

;; ----------------------------------------

(report-errs)
