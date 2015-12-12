(ns helper.fixture
  (:require [camel-snake-kebab.core        :as ksk]
            [nucleotides.database.migrate  :as build]
            [helper.database               :as db]))

(defn test-directory [which]
  (str "test/" (ksk/->snake_case_string which)))

(defn fetch-test-data [x]
  (build/load-data-file (test-directory :data) x))

(defn load-fixture [& fixtures]
  (db/empty-database)
  (dorun
    (for [f fixtures]
      (db/exec-db-command (slurp (str "test/fixtures/" f ".sql"))))))
