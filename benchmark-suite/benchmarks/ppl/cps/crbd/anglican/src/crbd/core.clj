(ns crbd.core
  (:require [clojure.tools.cli :refer [parse-opts]])
  (:use [anglican [core :exclude [-main cli-options parse-options]] emit runtime]
        clojure.pprint)
  (:gen-class))

(def^:const tree
  {:type :node,
   :left {:type :node,
          :left {:type :node,
                 :left {:type :node,
                        :left {:type :leaf, :age 0.0},
                        :right {:type :leaf, :age 0.0},
                        :age 5.635787971},
                 :right {:type :node,
                         :left {:type :leaf, :age 0.0},
                         :right {:type :node,
                                 :left {:type :leaf, :age 0.0},
                                 :right {:type :node,
                                         :left {:type :leaf, :age 0.0},
                                         :right {:type :leaf, :age 0.0},
                                         :age 4.788021775},
                                 :age 7.595901077},
                         :age 9.436625313},
                 :age 12.344087935000001},
          :right {:type :node,
                  :left {:type :node,
                         :left {:type :leaf,
                                :age 0.0},
                         :right {:type :node,
                                 :left {:type :node,
                                        :left {:type :leaf, :age 0.0},
                                        :right {:type :leaf, :age 0.0},
                                        :age 3.934203877},
                                 :right {:type :node,
                                         :left {:type :node,
                                                :left {:type :leaf, :age 0.0},
                                                :right {:type :leaf, :age 0.0},
                                                :age 3.151799953},
                                         :right {:type :node,
                                                 :left {:type :leaf, :age 0.0},
                                                 :right {:type :leaf, :age 0.0},
                                                 :age 5.054547857},
                                         :age 6.284896356999999},
                                 :age 7.815689970999999},
                         :age 10.32243059},
                  :right {:type :node,
                          :left {:type :leaf, :age 0.0},
                          :right {:type :node,
                                  :left {:type :node,
                                         :left {:type :leaf, :age 0.0},
                                         :right {:type :node,
                                                 :left {:type :leaf, :age 0.0},
                                                 :right {:type :leaf, :age 0.0},
                                                 :age 1.519406055},
                                         :age 4.987038163},
                                  :right {:type :node,
                                          :left {:type :leaf, :age 0.0},
                                          :right {:type :node,
                                                  :left {:type :node,
                                                         :left {:type :leaf, :age 0.0},
                                                         :right {:type :leaf, :age 0.0},
                                                         :age 0.6302632958},
                                                  :right {:type :node,
                                                          :left {:type :leaf, :age 0.0},
                                                          :right {:type :node,
                                                                  :left {:type :leaf, :age 0.0},
                                                                  :right {:type :leaf, :age 0.0},
                                                                  :age 1.962579854},
                                                          :age 3.732932004},
                                                  :age 5.5933070698},
                                          :age 6.096453021},
                                  :age 8.265483252},
                          :age 10.86835485},
                  :age 12.551924091},
          :age 13.472886809},
   :right {:type :node,
           :left {:type :node,
                  :left {:type :node,
                         :left {:type :leaf, :age 0.0},
                         :right {:type :node,
                                 :left {:type :leaf, :age 0.0},
                                 :right {:type :leaf, :age 0.0},
                                 :age 4.534421013},
                         :age 12.46869821},
                  :right {:type :node,
                          :left {:type :leaf, :age 0.0},
                          :right {:type :node,
                                  :left {:type :leaf, :age 0.0},
                                  :right {:type :node,
                                          :left {:type :leaf, :age 0.0},
                                          :right {:type :node,
                                                  :left {:type :leaf, :age 0.0},
                                                  :right {:type :leaf, :age 0.0},
                                                  :age 6.306427821},
                                          :age 9.40050129},
                                  :age 13.85876825},
                          :age 20.68766993},
                  :age 22.82622451},
           :right {:type :node,
                   :left {:type :leaf, :age 0.0},
                   :right {:type :node,
                           :left {:type :node,
                                  :left {:type :leaf, :age 0.0},
                                  :right {:type :node,
                                          :left {:type :leaf, :age 0.0},
                                          :right {:type :node,
                                                  :left {:type :leaf, :age 0.0},
                                                  :right {:type :node,
                                                          :left {:type :leaf, :age 0.0},
                                                          :right {:type :leaf, :age 0.0},
                                                          :age 4.220057646},
                                                  :age 8.451051062},
                                          :age 11.54072627},
                                  :age 15.28839572},
                           :right {:type :node,
                                   :left {:type :node,
                                          :left {:type :node,
                                                 :left {:type :leaf, :age 0.0},
                                                 :right {:type :leaf, :age 0.0},
                                                 :age 8.614086751},
                                          :right {:type :node,
                                                  :left {:type :leaf, :age 0.0},
                                                  :right {:type :node,
                                                          :left {:type :leaf, :age 0.0},
                                                          :right {:type :node,
                                                                  :left {:type :leaf, :age 0.0},
                                                                  :right {:type :node,
                                                                          :left {:type :node,
                                                                                 :left {:type :leaf, :age 0.0},
                                                                                 :right {:type :leaf, :age 0.0},
                                                                                 :age 0.9841688636},
                                                                          :right {:type :node,
                                                                                  :left {:type :leaf, :age 0.0},
                                                                                  :right {:type :leaf, :age 0.0},
                                                                                  :age 1.04896206}, :age 1.7140599232},
                                                                  :age 3.786162534},
                                                          :age 8.788450495},
                                                  :age 11.05846217},
                                          :age 15.008504768},
                                   :right {:type :node,
                                           :left {:type :node,
                                                  :left {:type :leaf, :age 0.0},
                                                  :right {:type :leaf, :age 0.0},
                                                  :age 11.15685875},
                                           :right {:type :node,
                                                   :left {:type :leaf, :age 0.0},
                                                   :right {:type :node,
                                                           :left {:type :leaf, :age 0.0},
                                                           :right {:type :node,
                                                                   :left {:type :leaf, :age 0.0},
                                                                   :right {:type :node,
                                                                           :left {:type :leaf, :age 0.0},
                                                                           :right {:type :node,
                                                                                   :left {:type :leaf, :age 0.0},
                                                                                   :right {:type :leaf, :age 0.0},
                                                                                   :age 1.900561313},
                                                                           :age 3.100150132},
                                                                   :age 6.043650727},
                                                           :age 12.38252513},
                                                   :age 12.61785812},
                                           :age 15.396725736},
                                   :age 16.828404506},
                           :age 20.368109703000002},
                   :age 23.74299959},
           :age 32.145876657},
   :age 34.940139089})

(def^:const rho 0.5684210526315789)

(defdist id
  "Hack to make the factor and condition functions work correctly"
  [] []

  ;; Sampling not allowed
  (sample* [this]
           (throw (Exception. "id-dist does not support sampling")))

  ;; The "log probability" of observing value is value itself
  (observe* [this value] value))

(with-primitive-procedures [id]
  ;; weight
  (defm factor [x]
    "WebPPL-like factor function"
    (observe (id) x))

  (defm condition [b]
    "WebPPL-like condition function"
    (if b (factor 0) (factor Double/NEGATIVE_INFINITY)))

  (defm count-leaves [tree]
    (case (:type tree)
      :node (+ (count-leaves (:left tree)) (count-leaves (:right tree)))
      :leaf 1))

  (defm log-factorial [n] (if (= n 1) 0 (+ (log n) (log-factorial (- n 1))))))

(defquery crbd
  (let [lambda (sample (gamma 1 1))    ;note gamma is parametrized as shape/rate
        mu (sample (gamma 1 2))
        survives (fn survives [t-beg]
                   (let [t (- t-beg (sample (exponential (+ lambda mu))))]
                     (if (< t 0)
                       (sample (flip rho))
                       (if (sample (flip (/ lambda (+ lambda mu))))
                         (or (survives t) (survives t))
                         false))))
        walk (fn walk [tree parent-age]
               (let [sim-hidden-speciation
                     (fn sim-hidden-speciation [t-beg]
                       (let [t (- t-beg (sample (exponential lambda)) )]
                         (if (> t (:age tree))
                           (if (survives t)
                             Double/NEGATIVE_INFINITY
                             (+ (log 2) (sim-hidden-speciation t)))
                           0)))
                     score (+ (sim-hidden-speciation parent-age)
                              (observe*
                               (poisson (* mu (- parent-age (:age tree))))
                               0))]
                 (case (:type tree)
                   :node (do
                           (factor (+ score (observe* (exponential lambda) 0)))
                           (walk (:left tree) (:age tree))
                           (walk (:right tree) (:age tree)))
                   :leaf (factor (+ score (observe* (bernoulli rho) 1))))))
        num-leaves (count-leaves tree)]

    (factor (- (* (- num-leaves 1) (log 2)) (log-factorial num-leaves)))
    (walk (:left tree) (:age tree))
    (walk (:right tree) (:age tree))
    lambda))

(def cli-options
  [["-m" "--method METHOD" "Inference method, one of :importance, :pimh, :lmh, or :smc"
    :default :importance
    :parse-fn #(case %
                 ":importance" :importance
                 ":pimh" :pimh
                 ":lmh" :lmh
                 ":smc" :smc)
    :validate [some? "Must be a known algorithm"]]
   ["-p" "--particles COUNT" "Number of particles"
    :default 10
    :parse-fn #(Integer/parseInt %)
    :validate [#(< 0 %) "Must be a number greater than 0"]]
   ["-o" "--output" "Output samples to stdout"]
   ["-h" "--help"]])

(defn int-or-nil [number-string]
  (try (Integer/parseInt number-string) (catch Exception e nil)))

(defn parse-args [args] (if (= (count args) 1) (int-or-nil (first args))))

(defn -main [& args]
  (let [opts (parse-opts args cli-options)
        nsamples (parse-args (:arguments opts))]
    (if (some? (:errors opts))
      (do (println (:errors opts)) (println (:summary opts)) (System/exit 1))
      (if (not (some? nsamples))
        (do (println (:summary opts)) (System/exit 1))
        (let [opts (:options opts)
              samples
              (doall (take nsamples
                           (case (:method opts)
                             (:smc :pimh) (doquery (:method opts)
                                                   crbd
                                                   nil
                                                   :number-of-particles
                                                   (:particles opts))
                             (doquery (:method opts) crbd nil))))]
          (when (some? (:output opts))
            (run! #(printf "%f %f\n" (:result %) (:log-weight %)) samples)))))))
