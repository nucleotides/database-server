(ns nucleotides.api.status
  (:require [yesql.core                      :refer [defqueries]]
            [nucleotides.database.connection :as con]))

(defqueries "nucleotides/api/status.sql")

(defn show
  "Returns a map containing the current status of benchmarking"
  [db-client]
  (let [tasks (->> (benchmark-task-status {} db-client)
                   (group-by :task_type)
                   (reduce-kv #(assoc %1 %2 (dissoc (first %3) :task_type)) {}))]
    {:tasks tasks}))
