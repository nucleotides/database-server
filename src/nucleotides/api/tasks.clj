(ns nucleotides.api.tasks
  (:require [clojure.set         :as st]
            [yesql.core          :refer [defqueries]]
            [ring.util.response  :as ring]))

(defqueries "nucleotides/api/tasks.sql")
(defqueries "nucleotides/api/benchmarks.sql")

(defn show
  "Returns all incomplete tasks"
  [db-client _]
  (ring/response (incomplete-tasks {} db-client)))

(defn lookup
  "Gets a single task entry by its ID"
  [db-client id _]
  (let [task  (first (task-by-id {:id id} db-client))
        files (benchmark-produce-files-by-id {:id (:benchmark_instance_id task)} db-client)]
    (-> task
        (assoc :files files)
        (dissoc :benchmark_instance_id)
        (st/rename-keys {:external_id :benchmark})
        (ring/response))))


