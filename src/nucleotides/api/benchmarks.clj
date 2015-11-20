(ns nucleotides.api.benchmarks
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [clojure.data.json   :as json]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn parse-boolean [v]
  (cond
    (.equalsIgnoreCase v "true")   true
    (.equalsIgnoreCase v "false")  false
    :else v))

(def parse-values
  (comp
    (partial into {})
    (partial map (fn [[k v]] [k (parse-boolean v)]))))

(defn show
  "Returns all benchmarks, can be parameterised by product/evaluation completed or
  not."
  [db-client {params :params}]
  {:status 200
   :body   ((cond
              (contains? params :evaluation) benchmarks-by-eval
              (contains? params :product)    benchmarks-by-product
              :else                          benchmarks)
            (parse-values params) {:connection db-client})})
