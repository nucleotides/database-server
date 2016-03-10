(ns nucleotides.api.metrics
  (:require [yesql.core          :refer [defqueries]]
            [clojure.string                  :as st]
            [nucleotides.database.connection :as con]))

(defqueries "nucleotides/api/metrics.sql")

(defn invalid-metrics
  "Returns a list of invalid metric types"
  [xs]
  (let [to-str  #(st/replace (str %) ":" "")
        allowed (->> {:connection (con/create-connection)}
                     (all-metric-types {})
                     (map :name)
                     (into #{}))]
    (clojure.set/difference (set (map to-str xs)) allowed)))
