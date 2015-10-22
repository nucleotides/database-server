(ns nucleotides.database.build
  (:gen-class)
  (:require
    [clojure.walk                    :as walk]
    [clojure.set                     :as st]
    [yesql.core                      :refer [defqueries]]
    [migratus.core                   :as mg]
    [nucleotides.util                :as util]
    [nucleotides.database.connection :as con]))


(defqueries "nucleotides/database/queries.sql")

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})


(defn load-image-types
  "Select the image types and load into the database"
  [connection data]
  (for [entry data]
    (-> entry
        (select-keys ["image_type", "description"])
        (walk/keywordize-keys)
        (st/rename-keys {:image_type :name})
        (save-image-type! {:connection connection}))))


(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (do
    (load-image-types connection (:images data))))

(defn migrate [connection initial-data]
  (do
    (mg/migrate (create-migratus-spec connection))
    (load-data connection initial-data)))

(defn -main [& args]
  (do
    (migrate (con/create-connection))
    (System/exit 0)))
