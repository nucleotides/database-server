(ns nucleotides.api.events
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [ring.util.response  :as ring]
            ))

(defqueries "nucleotides/api/events.sql")

(def wide->long
  (partial map
     (fn [x]
       (->> x
            (walk/postwalk #(if (keyword? %) (st/replace (str %) ":" "") %))
            (interleave [:name :value])
            (apply hash-map)))))

(defn- create-event [db-client params]
  (let [f #(create-benchmark-event<! % db-client)]
   (if-not (contains? params :benchmark_file)
    (f (assoc params :benchmark_file nil))
    (f params))))

(defn- create-metrics [db-client id {:keys [event_type success metrics]}]
  (if (and (= event_type "evaluation") (= success "true"))
    (->> metrics
         (wide->long)
         (map #(assoc % :id id))
         (map #(create-metric-instance<! % db-client))
         (dorun))))

(defn create
  "Creates a new benchmark event from the given parameters"
  [db-client {params :params}]
  (let [id (:id (create-event db-client params))
        _  (create-metrics db-client id params)]
    (ring/response (str id))))
