(ns nucleotides.database.build-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc          :as sql]
            [taoensso.timbre            :as log]
            [nucleotides.database.build :as build]))

; Silence logging to STDOUT during testing
(log/set-config! [:appenders :standard-out :enabled? false])

(def database-name "clojure_test_db")

(defn exec-db-command [command]
  (sql/with-db-connection [conn (build/create-sql-params)]
    (with-open [s (.createStatement (:connection conn))]
      (.executeUpdate s command))))

(defn refresh-testing-database [f]
  (do
    (exec-db-command (str "drop database if exists " database-name))
    (exec-db-command (str "create database " database-name))
    (f)))

(use-fixtures
  :each refresh-testing-database)
