(ns nucleotides.api.status
  (:require [yesql.core :refer [defqueries]]))

(defqueries "nucleotides/api/status.sql")

(defn show
  "Returns a map containing the current status of benchmarking"
  [db-client] {})
