(ns nucleotides.database.load
  (:require
    [clojure.set  :as    st]
    [yesql.core   :refer [defqueries]]
    [nucleotides.database.connection :as con]))

(defqueries "nucleotides/database/queries.sql")

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


(def data-types
  "Load data types into the database"
  (load-entries save-data-type<!))


(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (do
    (image-types connection (:image data))
    (data-types connection  (:data_type data))))
