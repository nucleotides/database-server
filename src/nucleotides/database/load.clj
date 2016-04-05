(ns nucleotides.database.load
  (:require
    [clojure.set              :as st]
    [clojure.java.jdbc        :as sql]
    [com.rpl.specter          :refer :all]
    [yesql.core               :refer [defqueries]]
    [nucleotides.database.connection :as con]))

(defqueries "nucleotides/database/queries.sql")

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
  "Takes a save and optional transform function, returns a new function that
  applies 'transform' and then maps the 'save' over the data."
  ([f save]
   (fn [data]
     (->> (f data)
          (map #(save % {:connection (con/create-connection)}))
          (dorun))))
  ([save]
   (load-entries identity save)))

(def biological-sources
  "Loads input data sources into the database"
  (load-entries save-biological-source<!))

(def biological-source-files
  "Loads references into file_instance table and links to input_data_source"
  (load-entries (partial select-file-entries :references) save-biological-source-file<!))

(def input-data-file-set
  "Load entries into the 'input_data_file_set' table"
  (load-entries save-input-data-file-set<!))

(def input-data-files
  "Loads entries into 'file_instance' and links to 'input_data_file_set'"
  (load-entries (partial select-file-entries :files) save-input-data-file<!))

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

(def loaders
  [[biological-sources       :biological-source]
   [biological-source-files  :biological-source]
   [input-data-file-set      :file]
   [input-data-files         :file]
   [image-instances          :image]])


(defn load-all-input-data
  "Load and update benchmark data in the database"
  [data]
  (dorun
    (for [[f k] loaders]
      (f (k data)))))
