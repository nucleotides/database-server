(ns nucleotides.database.load
  (:require
    [clojure.set              :as st]
    [clojure.java.jdbc        :as sql]
    [com.rpl.specter          :refer :all]
    [camel-snake-kebab.core   :as ksk]
    [yesql.core               :refer [defqueries]]
    [nucleotides.database.connection :as con]))

(defqueries "nucleotides/database/queries.sql")

(defn unfold-data-replicates [entries]
  (let [select-fields (partial select
                               [ALL (collect-one :name)
                                    (keypath :entries)
                                ALL (collect-one :reference)
                                    (collect-one :reads)
                                    (collect-one :entry_id)
                                    (keypath :replicates)])]
    (mapcat
      (fn [[name reference reads entry-id replicates]]
        (let [entry-data {:reference_url (:url    reference)
                          :reference_md5 (:md5sum reference)
                          :name          name
                          :reads         reads
                          :entry_id      entry-id}]
          (map-indexed
            (fn [idx rep]
              (-> (st/rename-keys rep {:md5sum :input_md5 :url :input_url})
                  (assoc :replicate (inc idx))
                  (merge entry-data)))
            replicates)))
      (select-fields entries))))

(defn metadata-types [connection table-name data]
  (let [query "INSERT INTO %1$s (name, description)
               SELECT '%2$s', '%3$s'
               WHERE NOT EXISTS (SELECT id FROM %1$s WHERE name = '%2$s')
               RETURNING id;"
      save! (fn [entry]
              (sql/query connection
               (format query
                       (str (ksk/->snake_case_string table-name) "_type")
                       (:name entry)
                       (:desc entry))))]
    (dorun (map save! data))))

(defn select-file-entries [k entries]
  (->> entries
       (mapcat (partial select [(collect-one :name) (keypath k) ALL]))
       (remove empty?)
       (map #(assoc (last %) :source_name (first %)))))


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

(def input-data-sources
  "Loads input data sources into the database"
  (load-entries save-input-data-source<!))

(def input-data-source-files
  "Loads references into file_instance and links to input_data_source"
  (load-entries (partial select-file-entries :references) save-input-data-source-file<!))

(def input-data-file-set
  "Load entries into the 'input_data_file_set' table"
  (load-entries save-input-data-file-set<!))

(def input-data-files
  "Loads entries into 'file_instance' and links to 'input_data_file_set'"
  (load-entries (partial select-file-entries :replicates) save-input-data-file<!))

(def image-instances
  "Select the image instances and load into the database"
  (let [transform (partial select [ALL (collect-one :image_type) (keypath :image_instances)
                                   ALL (collect-one :sha256) (keypath :name)])
        zip       (partial map (partial zipmap [:image_type :sha256 :name]))]
    (load-entries (fn [entries] (zip (transform entries))) save-image-instance<!)))

(def image-tasks
  "Select the image tasks and load into the database"
  (let [transform (partial select [ALL (keypath :image_instances)
                                   ALL (collect-one :name) (collect-one :sha256) (keypath :tasks)
                                   ALL])
        zip       (partial map (partial zipmap [:name :sha256 :task]))]
    (load-entries (fn [entries] (zip (transform entries))) save-image-task<!)))

(def data-sets
  "Load data sets into the database"
  (let [transform #(select-keys % [:name, :description])]
  (load-entries (partial map transform) save-data-set<!)))

(def data-records
  "Load data records into the database"
  (load-entries unfold-data-replicates save-data-record<!))

(def benchmark-types
  "Load benchmark types into the database"
  (let [f (fn [acc entry]
            (let [benchmark (dissoc entry :data_sets)]
              (->> (:data_sets entry)
                   (map (partial assoc benchmark :data_set_name))
                   (concat acc))))
        transform (partial reduce f [])]
    (load-entries transform save-benchmark-type<!)))

(defn rebuild-benchmark-task [connection]
  (let [args [{} {:connection connection}]]
    (apply populate-benchmark-instance! args)
    (apply populate-task! args)))

(def metadata-entries
  [:platform :file :metric :protocol :product :run-mode :source :image])

(def loaders
  [[input-data-sources       :data-source]
   [input-data-source-files  :data-source]
   [input-data-file-set      :data-file]
   [input-data-files         :data-file]
   [data-sets                :data]
   [data-records             :data]
   [image-instances          :image-instance]
   [image-tasks              :image-instance]
   [benchmark-types          :benchmark-type]])

(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (let [load_         (fn [[f k]] (f connection (k data)))
        load-metadata #(metadata-types connection % (% data))]
    (do
      (dorun (map load-metadata metadata-entries))
      (dorun (map load_ loaders))
      (rebuild-benchmark-task connection))))
