(ns nucleotides.api.events
  (:require [yesql.core          :refer [defqueries]]
            [ring.util.response  :as ring]
            [clojure.data.json   :as json]
            ))

(defqueries "nucleotides/api/events.sql")

(def wide->long
  (partial map #(->> (interleave [:name :value] %)
                     (apply hash-map))))

(defn- create-event [db-client params]
  (let [f #(create-benchmark-event<! % {:connection db-client})]
   (if-not (contains? params :benchmark_file)
    (f (assoc params :benchmark_file nil))
    (f params))))

(defn- create-metrics [db-client id {:keys [event_type success metrics]}]
  (if (and (= event_type "evaluation") (= success "true"))
    (->> metrics
         (json/read-str)
         (wide->long)
         (map #(assoc % :id id))
         (map #(create-metric-instance<! % {:connection db-client}))
         (dorun))))

(defn create
  "Creates a new benchmark event from the given parameters"
  [db-client {params :params}]
  (let [id (:id (create-event db-client params))
        _  (create-metrics db-client id params)]
    (ring/response (str id))))
