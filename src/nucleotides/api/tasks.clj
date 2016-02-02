(ns nucleotides.api.tasks
  (:require [clojure.set         :as st]
            [yesql.core          :refer [defqueries]]
            [ring.util.response  :as ring]))

(defqueries "nucleotides/api/tasks.sql")

(defn show
  "Returns all incomplete tasks"
  [db-client _]
  (ring/response (incomplete-tasks {} db-client)))

(defn lookup
  "Gets a single task entry by its ID"
  [db-client id _]
  (-> (task-by-id {:id id} db-client)
      (first)
      (dissoc :benchmark_instance_id)
      (st/rename-keys {:external_id :benchmark})
      (ring/response)))
