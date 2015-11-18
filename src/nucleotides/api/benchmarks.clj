(ns nucleotides.api.benchmarks
  (:require [clojure.core.match  :refer [match]]
            [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [clojure.data.json   :as json]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn json-response [f args db-client]
  {:status 200
   :body   (->> {:connection db-client}
                (f args)
                (json/write-str))})

(defn parse-boolean [v]
  (cond
    (.equalsIgnoreCase v "true")   true
    (.equalsIgnoreCase v "false")  false
    :else v))

(def parse-keys
  (comp
    (partial into {})
    (partial map (fn [[k v]] [k (parse-boolean v)]))))

(defn show
  "Returns all benchmarks, can be parameterised by completed or not."
  [db-client {params :params}]
  (let [{:keys [product evaluation]} (parse-keys params)]
    (match [product evaluation]
           [nil nil] (json-response benchmarks            params db-client)
           [_   nil] (json-response benchmarks-by-product params db-client)
           :else     (json-response benchmarks-by-eval    params db-client))))
