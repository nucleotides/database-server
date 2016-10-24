(ns nucleotides.database.connection
  (:require
    [jdbc.pool.c3p0   :as pool]
    [nucleotides.util :as util]))

(def env-var-names
  {:user      "PGUSER"
   :password  "PGPASSWORD"
   :host      "PGHOST"
   :port      "PGPORT"
   :db        "PGDATABASE"})

(defn sql-params [vars]
  {:classname    "org.postgresql.Driver"
   :subprotocol  "postgresql"
   :subname      (str "//" (:host vars) ":" (:port vars)  "/" (:db vars))
   :user         (:user vars)
   :password     (:password vars)})

(def connection-pool
  (->> (util/fetch-variables! env-var-names)
       (sql-params)
       (pool/make-datasource-spec)
       (delay)))

(defn create-connection []
  @connection-pool)
