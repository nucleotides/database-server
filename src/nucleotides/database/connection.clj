(ns nucleotides.database.connection
  (:require [nucleotides.util :as util]))

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
