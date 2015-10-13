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

(defn migrate []
  (let [sql-config  (con/create-sql-params)
        spec        (create-migratus-spec sql-config)]
    (mg/migrate spec)))

(defn -main [& args]
  (migrate))
