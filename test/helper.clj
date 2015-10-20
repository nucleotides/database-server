(ns helper
  (:require [taoensso.timbre                 :as log]
            [clojure.java.jdbc               :as sql]
            [nucleotides.database.connection :as con]))

(defn silence-logging! []
  (log/set-config! [:appenders :standard-out :enabled? false]))

(defn exec-db-command [command]
  (sql/with-db-connection [conn (con/create-connection)]
    (with-open [s (.createStatement (:connection conn))]
      (.executeUpdate s command))))

(defn refresh-testing-database [database-name]
  (fn [f]
    (do
      (exec-db-command (str "drop database if exists " database-name))
      (exec-db-command (str "create database " database-name))
      (f))))
