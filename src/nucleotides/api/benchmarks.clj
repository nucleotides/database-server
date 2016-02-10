(ns nucleotides.api.benchmarks
  (:require [yesql.core             :refer [defqueries]]
            [clojure.walk           :as walk]
            [clojure.set            :as st]
            [ring.util.response     :as ring]
            [taoensso.timbre        :as log]
            [nucleotides.api.events :as event]))


(defqueries "nucleotides/api/benchmarks.sql")

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (-> (benchmark-by-id {:id id} db-client)
      (first)
      (ring/response)))
