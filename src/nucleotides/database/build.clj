(ns nucleotides.database.build
  (:gen-class)
  (:require
    [clojure.java.jdbc :as sql]
    [nucleotides.util  :as util]
    [migratus.core     :as mg]))

(defn create-sql-params []
  (let [env-var-names {:user      "POSTGRES_USER"
                       :password  "POSTGRES_PASSWORD"
                       :host      "POSTGRES_HOST"}
        vars          (util/fetch-variables! env-var-names)]
    {:classname    "org.postgresql.Driver"
     :subprotocol  "postgresql"
     :subname      (:host vars)
     :user         (:user vars)
     :password     (:password vars)}))


(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn -main [& args]
  (let [sql-config  (create-sql-params)
        spec        (create-migratus-spec sql-config)]
    (mg/migrate spec)))
