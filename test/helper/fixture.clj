(ns helper.fixture
  (:require [clojure.string                :as st]
            [camel-snake-kebab.core        :as ksk]
            [nucleotides.database.migrate  :as build]
            [helper.database               :as db]))

(def base-fixtures
  [:metadata
   :input-data-source
   :input-data-file-set
   :input-data-file
   :image-instance
   :benchmarks
   :tasks])


(defn test-directory [& paths]
  (->> paths
       (map ksk/->snake_case_string)
       (concat ["test"])
       (st/join "/")))

(defn fixture-file [fixture]
  (test-directory "fixtures" (str (ksk/->snake_case_string fixture) ".sql")))

(defn load-fixture [& fixtures]
  (dorun
    (for [f fixtures]
      (->> f
           (fixture-file)
           (slurp)
           (db/exec-db-command)))))
