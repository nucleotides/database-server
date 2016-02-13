(ns nucleotides.database.load
  (:require
    [clojure.set              :as st]
    [clojure.java.jdbc        :as sql]
    [com.rpl.specter          :refer :all]
    [camel-snake-kebab.core   :as ksk]
    [yesql.core               :refer [defqueries]]
    [nucleotides.database.connection :as con]))

(defqueries "nucleotides/database/queries.sql")

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


(defn unfold-by-key [collection-key singleton-key entry]
  (map
    #(-> entry (dissoc collection-key) (assoc singleton-key %))
    (collection-key entry)))

(defn- load-entries
  "Creates a function that transforms and saves data with a given
  DB connection"
  ([f save]
   (fn [connection data]
     (->> (f data)
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
  (let [f (fn [entry]
            (map #(-> entry (dissoc :tasks) (assoc :task %)) (:tasks entry)))]
    (load-entries (partial mapcat f) save-image-instance<!)))

(def benchmarks
  "Load benchmark types into the database"
  (let [save #(do (save-benchmark-type<! %1 %2)
                  (save-benchmark-data<! %1 %2))]
   (load-entries
    (partial mapcat (partial unfold-by-key :input_data_file_sets :input_data_file_set))
    save)))

(defn rebuild-benchmark-task [connection]
  (let [args [{} {:connection connection}]]
    (apply populate-instance-and-task! args)))

(def metadata-entries
  [:platform :file :metric :protocol :product :run-mode :source :image])

(def loaders
  [[input-data-sources       :data-source]
   [input-data-source-files  :data-source]
   [input-data-file-set      :data-file]
   [input-data-files         :data-file]
   [image-instances          :image-instance]
   [benchmarks               :benchmark-type]])

(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (let [load_         (fn [[f k]] (f connection (k data)))
        load-metadata #(metadata-types connection % (% data))]
    (do
      (dorun (map load-metadata metadata-entries))
      (dorun (map load_ loaders))
      (rebuild-benchmark-task connection))))
