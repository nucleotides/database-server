(ns helper
  (:require [clojure.java.jdbc               :as sql]
            [taoensso.timbre                 :as log]
            [nucleotides.database.connection :as con]))

(defn silence-logging! []
  (log/set-config! [:appenders :standard-out :enabled? false]))

(defn exec-db-command [command]
  (sql/with-db-connection [conn (con/create-connection)]
    (with-open [s (.createStatement (:connection conn))]
      (.executeUpdate s command))))

(defn drop-all-tables []
  (do
    (exec-db-command "drop schema public cascade;")
    (exec-db-command "create schema public;")))
