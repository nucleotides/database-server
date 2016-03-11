(ns nucleotides.api.tasks
  (:require [clojure.set            :as st]
            [yesql.core             :refer [defqueries]]
            [nucleotides.api.events :as event]
            [nucleotides.api.util   :as util]))

(defqueries "nucleotides/api/tasks.sql")
(defqueries "nucleotides/api/benchmarks.sql")

(def image-keys
  {:image_name    :name,
   :image_sha256  :sha256,
   :image_task    :task
   :image_type    :type})

(defn create-submap [kvs ks k]
  (apply dissoc
         (->> (map (fn [[k v]] [v (k kvs)]) ks)
              (into {})
              (assoc kvs k))
         (keys ks)))

(defn get-task-files [db-client benchmark-instance-id task-type]
  "Fetch all input files for a given task"
  ((if (= "produce" task-type)
     benchmark-produce-files-by-id
     benchmark-evaluate-files-by-id)
     {:id benchmark-instance-id} db-client))

(defn get-events [db-client task-id]
  "Fetch all events for a given task"
  (doall
    (map #(event/lookup db-client (:id %) {})
         (events-by-task-id {:id task-id} db-client))))

(defn show
  "Returns all incomplete tasks"
  [db-client _]
  (->> (incomplete-tasks {} db-client)
       (map :id)))

(defn lookup
  "Gets a single task entry by its ID"
  [db-client id _]
  (let [task   (first (task-by-id {:id id} db-client))
        files  (get-task-files db-client (:benchmark_instance_id task) (:task_type task))
        events (get-events db-client id)]
    (-> task
        (assoc :inputs files)
        (assoc :events events)
        (dissoc :benchmark_instance_id)
        (st/rename-keys {:external_id :benchmark, :task_type :type})
        (create-submap image-keys :image))))

(def exists?
  (util/integer-id-exists-fn? task-by-id))
