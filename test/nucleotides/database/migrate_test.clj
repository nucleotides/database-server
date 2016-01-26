(ns nucleotides.database.migrate-test
  (:require [clojure.test     :refer :all]
            [helper.fixture   :refer :all]
            [helper.database  :refer :all]

            [nucleotides.database.migrate  :as migrate]))

(use-fixtures :each (fn [f] (drop-tables) (f)))

(def tables
  [:platform-type
   :protocol-type
   :product-type
   :source-type
   :file-type
   :metric-type
   :run-mode-type

   :input-data-source

   :image-type
   :image-instance
   :image-instance-task
   :data-set
   :data-record
   :benchmark-type
   :benchmark-instance
   :benchmark-data
   :task])

(deftest migrate
  (testing "-main"
    (migrate/migrate (test-directory :data))
    (dorun (for [table-name tables]
             (is (not (= 0 (table-length table-name))) (str table-name))))))
