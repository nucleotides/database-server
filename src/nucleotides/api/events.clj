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

(defn- create-metrics [db-client id {:keys [event_type success metrics]}]
  (if (and (= event_type "evaluation") (= success "true"))
    (->> metrics
         (wide->long)
         (map #(assoc % :id id))
         (map #(create-metric-instance<! % db-client))
         (dorun))))

(defn create
  "Creates a new event from the given parameters"
  [db-client {params :params}]
  (let [entry (-> {:file_url nil, :file_md5 nil}
                  (merge params)
                  (create-event<! db-client))]
    (ring/created (str "/events/" (:id entry)))))
