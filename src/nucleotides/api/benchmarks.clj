(ns nucleotides.api.benchmarks
  (:require [yesql.core             :refer [defqueries]]
            [clojure.walk           :as walk]
            [clojure.set            :as st]
            [ring.util.response     :as ring]
            [taoensso.timbre        :as log]
            [nucleotides.api.tasks  :as task]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn fetch-task [db-client task-id]
  (-> (task/lookup db-client task-id {})
       (:body)
       (dissoc :benchmark_id)))


(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (let [benchmark (benchmark-by-id {:id id} db-client)
        tasks     (doall (map (comp (partial fetch-task db-client) :task_id) benchmark))]
   (-> benchmark
      (first)
      (assoc  :complete false)
      (dissoc :task_id)
      (assoc  :tasks tasks)
      (ring/response))))
