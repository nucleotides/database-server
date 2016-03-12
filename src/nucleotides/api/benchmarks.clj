(ns nucleotides.api.benchmarks
  (:require [yesql.core             :refer [defqueries]]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]
            [nucleotides.api.util             :as util]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn fetch-task [db-client task-id]
  (-> (task/lookup db-client task-id {})
      (dissoc :benchmark_id)))

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (let [benchmark (benchmark-by-id {:id id} db-client)
        tasks     (doall (map (comp (partial fetch-task db-client) :task_id) benchmark))
        complete  (every? :complete tasks)]
   (-> benchmark
      (first)
      (assoc  :complete complete)
      (dissoc :task_id)
      (assoc  :tasks tasks))))

(def exists?
  (util/exists-fn benchmark-by-id))
