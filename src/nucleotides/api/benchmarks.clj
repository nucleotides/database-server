(ns nucleotides.api.benchmarks
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [clojure.data.json   :as json]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn show
  "Returns all benchmarks, can be parameterised by product/evaluation completed or
  not."
  [db-client {params :params}]
  {:status 200
   :body   ((cond
              (contains? params :evaluation) benchmarks-by-eval
              (contains? params :product)    benchmarks-by-product
              :else                          benchmarks)
            params {:connection db-client})})

(defn create
  "Creates a new benchmark event from the given parameters"
  [db-client {params :params}]
  (->> (create-benchmark-event<! params {:connection db-client})
       (:id)
       (assoc {:status 201} :body)))
