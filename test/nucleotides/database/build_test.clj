(ns nucleotides.database.build-test
  (:require [clojure.test :refer :all]
            [helper                          :as help]
            [nucleotides.database.build      :as build]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]
            ))

(help/silence-logging!)

(def database-name "clojure_test_db")

(use-fixtures
  :each (help/refresh-testing-database database-name))

(deftest build
  (let [db-vars      (util/fetch-variables! con/env-var-names)
        test-db-vars (assoc db-vars :db database-name)
        conn         (con/sql-params test-db-vars)]
  (testing "#migrate"
    (is (not ('thrown? org.postgresql.util.PSQLException (build/migrate conn)))))))
