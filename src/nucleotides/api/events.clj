(ns nucleotides.api.events
  (:require [yesql.core            :refer [defqueries]]

            [clojure.walk             :as walk]
            [clojure.string           :as st]
            [nucleotides.api.metrics  :as metrics]
            [nucleotides.api.files    :as files]
            [nucleotides.api.util     :as util]))

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
  (let [id (-> body (create-event<! db-client) (:event_id))]
    (files/create-event-files db-client id (:files body))
    (create-metrics db-client id body)
    id))

(defn lookup
  "Finds an event by ID"
  [db-client id _]
  (let [id      {:id id}
        files   (future (files/get-event-file-instance id db-client))
        metrics (->> (metrics-by-event-id id db-client)
                     (long->wide)
                     (future))]
    (-> (get-event id db-client)
        (first)
        (clojure.set/rename-keys {:task_id :task, :event_id :id})
        (assoc :files @files)
        (assoc :metrics @metrics))))

(def exists?
  (util/integer-id-exists-fn? get-event))

(defn event-validation-errors [event]
  {"metrics"    (->> (:metrics event)
                     (keys)
                     (metrics/invalid-metrics))

  "file types"  (->> (:files event)
                      (map :type)
                      (files/invalid-files))})

(defn valid? [event]
  (every? empty? (vals (event-validation-errors event))))

(defn error-message [event]
  (let [format-errors (fn [[k v]]
                        (format "Unknown %s in request: %s" k (st/join ", " v)))]
    (->> (event-validation-errors event)
         (filter (comp not empty? last))
         (map format-errors)
         (st/join "\n"))))
