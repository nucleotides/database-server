(ns nucleotides.database.connection
  (:require
    [jdbc.pool.c3p0   :as pool]
    [nucleotides.util :as util]))

(def env-var-names
  {:user      "POSTGRES_USER"
   :password  "POSTGRES_PASSWORD"
   :host      "POSTGRES_HOST"
   :db        "POSTGRES_NAME"})

(defn sql-params [vars]
  {:classname    "org.postgresql.Driver"
   :subprotocol  "postgresql"
   :subname      (str (:host vars) "/" (:db vars))
   :user         (:user vars)
   :password     (:password vars)})

(def connection-pool
  (delay (pool/make-datasource-spec (sql-params (util/fetch-variables! env-var-names)))))

(defn create-connection []
  @connection-pool)
