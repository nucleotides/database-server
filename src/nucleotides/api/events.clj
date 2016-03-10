(ns nucleotides.api.events
  (:require [yesql.core            :refer [defqueries]]
            [clojure.walk          :as walk]
            [clojure.string        :as st]
            [nucleotides.api.util  :as util]))

(defqueries "nucleotides/api/events.sql")
(defqueries "nucleotides/api/metrics.sql")

(def wide->long
  (partial map
     (fn [x]
       (->> x
            (walk/postwalk #(if (keyword? %) (st/replace (str %) ":" "") %))
            (interleave [:name :value])
            (apply hash-map)))))

(def long->wide
  (comp
    #(dissoc % nil)
    (partial apply hash-map)
    flatten
    (partial map vals)))

(defn create-event-files [db-client event-id files]
  (dorun
    (for [f files]
      (create-event-file-instance<! (assoc f :event_id event-id) db-client))))

(defn- create-metrics [db-client id {:keys [metrics]}]
  (if (not (nil? metrics))
    (->> metrics
         (wide->long)
         (map #(assoc % :id id))
         (map #(create-metric-instance<! % db-client))
         (dorun))))

(defn create
  "Creates a new event from the given parameters"
  [db-client body]
  (let [id (-> body (create-event<! db-client) (:id))]
    (create-event-files db-client id (:files body))
    (create-metrics db-client id body)
    {::id id}))

(defn lookup
  "Finds an event by ID"
  [db-client id _]
  (let [id     {:id id}
        files   (future (get-event-file-instance id db-client))
        metrics (->> (metrics-by-event-id id db-client)
                     (long->wide)
                     (future))]
    (-> (get-event id db-client)
        (first)
        (clojure.set/rename-keys {:task_id :task})
        (assoc :files @files)
        (assoc :metrics @metrics))))

(defn exists? [id]
  (every?
    #(true? (% id))
    [#(not (nil? (re-find (re-pattern "^\\d+$") (str %))))
     (util/exists-fn get-event)]))
