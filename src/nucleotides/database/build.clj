(ns nucleotides.database.build
  (:gen-class)
  (:require
    [nucleotides.database.connection :as con]
    [migratus.core                   :as mg]))

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn migrate [connection]
  (mg/migrate (create-migratus-spec connection)))

(defn -main [& args]
  (do
    (migrate (con/create-connection))  
    (System/exit 0)))
