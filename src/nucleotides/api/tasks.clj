(ns nucleotides.api.tasks
  (:require [clojure.set         :as st]
            [yesql.core          :refer [defqueries]]
            [ring.util.response  :as ring]))

(defqueries "nucleotides/api/tasks.sql")
(defqueries "nucleotides/api/benchmarks.sql")

(defn get-task-files [db-client benchmark-instance-id task-type]
  ((if (= "produce" task-type)
     benchmark-produce-files-by-id
     benchmark-evaluate-files-by-id)
     {:id benchmark-instance-id} db-client))

(defn show
  "Returns all incomplete tasks"
  [db-client _]
  (ring/response (incomplete-tasks {} db-client)))

(defn lookup
  "Gets a single task entry by its ID"
  [db-client id _]
  (let [task  (first (task-by-id {:id id} db-client))
        files (get-task-files db-client (:benchmark_instance_id task) (:task_type task))]
    (-> task
        (assoc :files files)
        (dissoc :benchmark_instance_id)
        (st/rename-keys {:external_id :benchmark})
        (ring/response))))
