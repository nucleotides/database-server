(ns nucleotides.api.events
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [ring.util.response  :as ring]))

(defqueries "nucleotides/api/events.sql")

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

(defn- create-metrics [db-client id {:keys [success metrics]}]
  (if (and (= success "true") (not (nil? metrics)))
    (->> metrics
         (wide->long)
         (map #(assoc % :id id))
         (map #(create-metric-instance<! % db-client))
         (dorun))))

(defn create
  "Creates a new event from the given parameters"
  [db-client {:keys [params] :as request}]
  (let [id (-> params
               (create-event<! db-client)
               (:id))]
    (ring/created (str "/events/" id))))

(defn lookup
  "Finds an event by ID"
  [db-client id _]
  (-> {:id id}
      (get-event db-client)
      (first)
      (clojure.set/rename-keys {:task_id :task})
      (ring/response)))
