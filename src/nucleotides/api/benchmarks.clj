(ns nucleotides.api.benchmarks
  (:require [yesql.core             :refer [defqueries]]
            [clojure.walk           :as walk]
            [clojure.set            :as st]
            [ring.util.response     :as ring]
            [taoensso.timbre        :as log]
            [nucleotides.api.events :as event]))

(def image-keys
  {:image_name    :name,
   :image_sha256  :sha256,
   :image_task    :task
   :image_type    :type})

(defqueries "nucleotides/api/benchmarks.sql")

(defn create-submap [kvs ks k]
  (apply dissoc
         (->> (map (fn [[k v]] [v (k kvs)]) ks)
              (into {})
              (assoc kvs k))
         (keys ks)))

(defn lookup-metrics [db-client id]
  (->> (benchmark-metrics-by-id {:id id} db-client)
       (event/long->wide)))

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (-> (benchmark-by-id {:id id} db-client)
      (first)
      (create-submap image-keys :image)
      (assoc :complete false)
      (ring/response)))

(comment
  (merge
    {:product  (first (benchmark-product-by-id {:id id} db-client))
     :evaluate (into [] (benchmark-evaluations-by-id {:id id} db-client))
     :metrics  (lookup-metrics db-client id)}))
