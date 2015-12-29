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
   :image_task    :task})

(def product-keys
  {:product_file_url  :url,
   :product_file_md5  :md5,
   :product_log_url   :log})

(def evaluate-keys
  {:evaluate_file_url  :url,
   :evaluate_file_md5  :md5,
   :evaluate_log_url   :log})

(defqueries "nucleotides/api/benchmarks.sql")

(defn create-submap [kvs ks k]
  (apply dissoc
         (->> (map (fn [[k v]] [v (k kvs)]) ks)
              (into {})
              (assoc kvs k))
         (keys ks)))

(defn lookup-evaluations [db-client id]
  (->> (benchmark-evaluations-by-id {:id id} db-client)
       (map #(st/rename-keys % evaluate-keys))
       (into [])))

(defn lookup-metrics [db-client id]
  (->> (benchmark-metrics-by-id {:id id} db-client)
       (event/long->wide)))

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (-> (benchmark-by-id {:id id} db-client)
      (first)
      (st/rename-keys {:external_id :id})
      (dissoc :external_id)
      (create-submap image-keys :image)
      (create-submap product-keys :product)
      (assoc :evaluate (lookup-evaluations db-client id))
      (assoc :metrics  (lookup-metrics db-client id))
      (ring/response)))
