(ns nucleotides.database.load
  (:require
    [clojure.set              :as st]
    [clojure.java.jdbc        :as sql]
    [com.rpl.specter          :refer :all]
    [yesql.core               :refer [defqueries]]
    [nucleotides.database.connection :as con]))

(defqueries "nucleotides/database/queries.sql")

(defn unfold-data-replicates [entries]
  (let [select-fields (partial select
                               [ALL (collect-one :type)
                                    (keypath :entries)
                                ALL (collect-one :reference)
                                    (collect-one :reads)
                                    (collect-one :entry_id)
                                    (keypath :replicates)])]
    (mapcat
      (fn [[data-type reference reads entry-id replicates]]
        (let [entry-data {:reference_url (:url    reference)
                          :reference_md5 (:md5sum reference)
                          :data_type      data-type
                          :reads reads
                          :entry_id entry-id}]
          (map-indexed
            (fn [idx rep]
              (-> (st/rename-keys rep {:md5sum :input_md5 :url :input_url})
                  (assoc :replicate (inc idx))
                  (merge entry-data)))
            replicates)))
      (select-fields entries))))


(defn- load-entries
  "Creates a function that transforms and saves data with a given
  DB connection"
  ([transform save]
   (fn [connection data]
     (->> (transform data)
          (map #(save % {:connection connection}))
          (dorun))))
  ([save]
   (load-entries identity save)))


(def image-types
  "Select the image types and load into the database"
  (let [transform (fn [entry] (-> entry
                                  (select-keys [:image_type, :description])
                                  (st/rename-keys {:image_type :name})))]
    (load-entries (partial map transform) save-image-type<!)))

(def image-tasks
  "Select the image tasks and load into the database"
  (let [transform
        (partial select [ALL (collect-one :image_type) (keypath :image_instances)
                         ALL (collect-one :name) (collect-one :sha256) (keypath :tasks)
                         ALL])
        zip      (partial map (partial zipmap [:image_type :name :sha256 :task]))]
    (load-entries (fn [entries] (zip (transform entries))) save-image-task<!)))



(def data-types
  "Load data types into the database"
  (let [transform #(select-keys % [:name, :library, :type, :description])]
  (load-entries (partial map transform) save-data-type<!)))

(def data-instances
  "Load data entries into the database"
  (load-entries unfold-data-replicates save-data-instance<!))

(def benchmark-types
  "Load benchmark types into the database"
  (load-entries save-benchmark-type<!))

(defn rebuild-benchmark-instance [connection]
  (sql/execute! connection ["REFRESH MATERIALIZED VIEW benchmark_instance;"])
  (sql/execute! connection ["REINDEX TABLE benchmark_instance;"]))

(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (do
    (image-types      connection (:image data))
    (image-tasks      connection (:image data))
    (data-types       connection (:data  data))
    (data-instances   connection (:data  data))
    (benchmark-types  connection (:benchmark_type  data))
    (rebuild-benchmark-instance connection)))

