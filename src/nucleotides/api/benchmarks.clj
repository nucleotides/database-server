(ns nucleotides.api.benchmarks
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.set         :as st]
            [ring.util.response  :as ring]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(defn create-submap [kvs ks k]
  (apply dissoc
         (->> (map (fn [[k v]] [v (k kvs)]) ks)
              (into {})
              (assoc kvs k))
         (keys ks)))

(def image-keys
  {:image_name    :name,
   :image_sha256  :sha256,
   :image_task    :task})

(def product-keys
  {:product_file_url  :url,
   :product_file_md5  :md5,
   :product_log_url   :log})


(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (-> (benchmark-by-id {:id id} db-client)
      (first)
      (st/rename-keys {:external_id :id})
      (dissoc :external_id)
      (create-submap image-keys :image)
      (create-submap product-keys :product)
      (ring/response)))
