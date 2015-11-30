(ns nucleotides.api.benchmarks
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [ring.util.response  :as ring]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(def long->wide
  (comp
    #(dissoc % nil)
    (partial apply hash-map)
    flatten
    (partial map vals)))

(defn show
  "Returns all benchmarks, can be parameterised by product/evaluation completed or
  not."
  [db-client {params :params}]
  (ring/response
    ((cond
       (contains? params :evaluation) benchmarks-by-eval
       (contains? params :product)    benchmarks-by-product
       :else                          benchmarks)
     params db-client)))

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (let [metrics (->> (metrics-by-benchmark-id {:id id} db-client)
                     (long->wide)
                     (future))] ; I put this here because I wanted to experiment
                                ; with clojure futures. This may not be optimal.
   (-> (benchmark-by-id {:id id} db-client)
       (first)
       (assoc :metrics @metrics)
       (ring/response))))
