(ns nucleotides.database.build-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc               :as db]
            [yesql.core                      :refer [defqueries]]
            [helper                          :as help]
            [nucleotides.database.build      :as build]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(use-fixtures :each (fn [f] (help/drop-tables) (f)))

(deftest build
  (testing "-main"
    (build/migrate help/test-data-directory)
    (is (= 2 (count (help/image-types))))
    (is (= 4 (count (help/image-tasks))))
    (is (= 1 (count (help/data-types))))
    (is (= 3 (count (help/data-instances))))
    (is (= 2 (count (help/benchmark-types))))))
