(ns nucleotides.database.migrate
  (:gen-class)
  (:require
    [migratus.core                   :as mg]
    [nucleotides.database.metadata   :as mtd]
    [nucleotides.database.load       :as ld]
    [nucleotides.database.files      :as files]
    [nucleotides.database.connection :as con]))

(defn create-migratus-spec []
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   (con/create-connection)})

(defn migrate [directory]
  (let [data (files/load-data-files directory)]
    (mg/migrate (create-migratus-spec))
    (mtd/load-all-metadata   (:cv data))
    (ld/load-all-input-data  data)
    (ld/populate-instance-and-task! {} {:connection (con/create-connection)})))

(defn -main [& args]
  (migrate (first args))
  (System/exit 0))
