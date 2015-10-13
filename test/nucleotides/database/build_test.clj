(ns nucleotides.database.build-test
  (:require [clojure.test :refer :all]
            [helper                     :as help]
            [nucleotides.database.build :as build]))

(help/silence-logging!)

(def database-name "clojure_test_db")

(use-fixtures
  :each (help/refresh-testing-database database-name))

(deftest build

  (testing "-main"
    

    ))
