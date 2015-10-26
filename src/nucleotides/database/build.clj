(ns nucleotides.database.build
  (:gen-class)
  (:require
    [migratus.core                   :as mg]
    [nucleotides.util                :as util]
    [nucleotides.database.load       :as loader]
    [nucleotides.database.connection :as con]))

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn migrate [connection initial-data]
  (do
    (mg/migrate (create-migratus-spec connection))
    (loader/load-data connection initial-data)))

(defn -main [& args]
  (do
    (migrate (con/create-connection))
    (System/exit 0)))
