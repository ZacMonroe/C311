#lang racket
(require rackunit)

; From a6
(define empty-k
  (lambda ()
    (lambda (v) v)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ACK ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define ack-orig
  (lambda (m n k)
    (cond
      [(zero? m) (k (add1 n))]
      [(zero? n) (ack-orig (sub1 m) 1 k)]
      [else (ack-orig m (sub1 n) (lambda (v) (ack-orig (sub1 m) v k)))])))


; Starting value of #f is arbitrary; ideally, it would be a value that is not
; allowed to be used or accessed legally
(define ack-m #f)
(define ack-n #f)
(define ack-k #f)
(define apply-ack-k-k #f)
(define apply-ack-k-v #f)

(define ack
  (lambda ()
    (cond
      [(zero? ack-m)
       (begin [set! apply-ack-k-k ack-k]
              [set! apply-ack-k-v (add1 ack-n)]
              (apply-ack-k))]
      [(zero? ack-n)
       (begin [set! ack-k ack-k]
              [set! ack-m (sub1 ack-m)]
              [set! ack-n 1]
              (ack))]
      [else
       (begin [set! ack-k (make-ack-k ack-m ack-k)]
              [set! ack-m ack-m]
              [set! ack-n (sub1 ack-n)]
              (ack))])))

(define make-ack-k
  (lambda (m k)
    `(make-ack-k ,m ,k)))

 (define empty-ack-k
  (lambda ()
    `(empty-ack-k)))

 (define apply-ack-k
  (lambda ()
    (match apply-ack-k-k
      [`(make-ack-k ,m ,k)
       (begin [set! ack-k k]
              [set! ack-m (sub1 m)]
              [set! ack-n apply-ack-k-v]
         (ack))]
      [`(empty-ack-k) apply-ack-k-v])))

(define ack-reg-driver
  (lambda (m n)
    (begin [set! ack-k (empty-ack-k)]
           [set! ack-m m]
           [set! ack-n n]
           (ack))))

; I don't want to figure out the result of actual ack calls so these tests are
; just going to compare to the original ack
(define ack-tests-data
  (list (cons 0 0)
        (cons 1 1)
        (cons 0 1)
        (cons 1 0)
        (cons 2 0)
        (cons 3 0)
        (cons 4 0)
        (cons 3 1)
        (cons 3 2)
        (cons 3 3)
        (cons 3 4)
        (cons 3 5)
        (cons 3 6)))

(for-each
 (lambda (test-case)
   (check-equal? (ack-reg-driver (car test-case) (cdr test-case))
                 (ack-orig (car test-case) (cdr test-case) (empty-k))))
 ack-tests-data)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Depth ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define depth-orig
  (lambda (ls k)
    (cond
      [(null? ls) (k 1)]
      [(pair? (car ls))
       (depth-orig (car ls)
                   (lambda (l)
                     (depth-orig (cdr ls)
                                 (lambda (r)
                                   (let ((l (add1 l)))
                                     (if (< l r) (k r) (k l)))))))]
      [else (depth-orig (cdr ls) k)])))


(define depth-ls #f)
(define depth-k #f)
(define apply-depth-k-k #f)
(define apply-depth-k-v #f)

(define depth
  (lambda ()
    (cond
      [(null? depth-ls)
       (begin [set! apply-depth-k-k depth-k]
              [set! apply-depth-k-v 1]
              (apply-depth-k))]
      [(pair? (car depth-ls))
       (begin [set! depth-k (make-k-depth-car depth-ls depth-k)]
              [set! depth-ls (car depth-ls)]
              (depth))]
      [else (begin [set! depth-k depth-k]
                   [set! depth-ls (cdr depth-ls)]
                   (depth))])))

(define make-k-depth-cdr
  (lambda (l k)
    `(make-k-depth-cdr ,l ,k)))

(define make-k-depth-car
  (lambda (ls k)
    `(make-k-depth-car ,ls ,k)))

(define make-k-depth-init
  (lambda ()
    `(empty-depth-k)))

(define apply-depth-k
  (lambda ()
    (match apply-depth-k-k
      [`(make-k-depth-car ,ls ,k)
       (begin [set! depth-k (make-k-depth-cdr apply-depth-k-v k)]
              [set! depth-ls (cdr ls)]
              (depth))]
      [`(make-k-depth-cdr ,l ,k)
       (let ([l (add1 l)])
         (if (< l apply-depth-k-v)
             (begin [set! apply-depth-k-k k]
                    [set! apply-depth-k-v apply-depth-k-v]
                    (apply-depth-k))
             (begin [set! apply-depth-k-k k]
                    [set! apply-depth-k-v l]
                    (apply-depth-k))))]
      [`(empty-depth-k) apply-depth-k-v])))

(define depth-tests-data
  '(()
    (1 (2 (3 (4))))
    (1 23  (21 ((((5 (5 (2)) 6) 6) 9) 1)) 0)
    (())
    (1 . ())
    ((1 ()) 3)
    ((1 2 (2 4 (1 ((3 4 (((((4) 6) 7) 8) 9) 1))))))
    ((((((((((((((()))))))))))))))
    (((((((((((((((1)))))))))))))))
    (1 2 3 4 6 7 2345 2354 2)
    ((((((((()))))))) . ((((((((((((((((((())))))))))))))))))))
    (ayo ayo asdfasdf asdf asdf asdf 2)))

(define depth-reg-driver
  (lambda (ls)
    (begin [set! depth-k (make-k-depth-init)]
           [set! depth-ls ls]
           (depth))))

(for-each
 (lambda (test-case)
   (check-equal? (depth-reg-driver test-case)
                 (depth-orig test-case (empty-k))))
 depth-tests-data)

