(ns nucleotides.api.status
  (:require [yesql.core                      :refer [defqueries]]
            [medley.core                     :as m]
            [nucleotides.database.connection :as con]))

(defqueries "nucleotides/api/status.sql")

(defn show
  "Returns a map containing the current status of benchmarking"
  [db-client]
  (let [tasks (->> (task-summary {} db-client)
                   (group-by :task_type)
                   (m/map-vals #(dissoc (first %) :task_type)))

        benchmarks (->> (benchmark-summary {} {:connection (con/create-connection)})
                        (group-by :benchmark_type)
                        (m/map-vals #(dissoc (first %) :benchmark_type)))]
    {:tasks       tasks
     :benchmarks  benchmarks}))
