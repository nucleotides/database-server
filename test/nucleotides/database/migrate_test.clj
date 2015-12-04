(ns nucleotides.database.migrate-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc               :as db]
            [yesql.core                      :refer [defqueries]]
            [helper                          :as help]
            [nucleotides.database.migrate    :as migrate]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(use-fixtures :each (fn [f] (help/drop-tables) (f)))

(def tables
  [:image-type
   :image-instance
   :image-instance-task
   :data-set
   :data-record
   :benchmark-type
   :benchmark-instance
   :benchmark-data
   :metric-type
   :task])

(do
  (help/drop-tables)
  (migrate/migrate help/test-data-directory))

(deftest migrate
  (testing "-main"
    (migrate/migrate help/test-data-directory)
    (dorun (for [table-name tables]
             (is (not (= 0 (help/table-length table-name))) (str table-name))))))
