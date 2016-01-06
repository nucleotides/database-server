(ns nucleotides.api.tasks
  (:require [yesql.core          :refer [defqueries]]
            [ring.util.response  :as ring]))

(defqueries "nucleotides/api/tasks.sql")

(defn show
  "Returns all incomplete tasks"
  [db-client _]
  (ring/response (incomplete-tasks {} db-client)))
