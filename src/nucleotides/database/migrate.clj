(ns nucleotides.database.migrate
  (:gen-class)
  (:require
    [migratus.core                   :as mg]
    [nucleotides.database.load       :as loader]
    [nucleotides.database.files      :as files]
    [nucleotides.database.connection :as con]))

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn migrate [directory]
  (let [data  (files/load-data-files directory)
        con   (con/create-connection)]
    (mg/migrate (create-migratus-spec con))
    (loader/load-data con data)))

(defn -main [& args]
  (migrate (first args))
  (System/exit 0))
