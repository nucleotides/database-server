(ns nucleotides.database.load
  (:require
    [clojure.walk :as    walk]
    [clojure.set  :as    st]
            [nucleotides.database.connection :as con]
    [yesql.core   :refer [defqueries]]))

(defqueries "nucleotides/database/queries.sql")

(defn- load-entries [transform save]
  "Creates a function that transforms and saves data with a given
  DB connection"
  (fn [connection data]
    (for [entry (transform data)]
      (-> entry
          (walk/keywordize-keys)
          (save {:connection connection})))))


(def image-types
  "Select the image types and load into the database"
  (let [transform (fn [entry]
                    (-> entry
                        (select-keys ["image_type", "description"])
                        (st/rename-keys {"image_type" "name"})))]
    (load-entries (partial map transform)  save-image-type<!)))


(def data-types
  "Load data types into the database"
  (load-entries identity save-data-type<!))


(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (load-image-types connection (:images data)))
