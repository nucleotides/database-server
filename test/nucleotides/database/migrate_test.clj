(ns nucleotides.database.migrate-test
  (:require [clojure.test     :refer :all]
            [helper.database  :refer :all]
            [nucleotides.database.migrate :as migrate]))

(def tables
  [:platform-type
   :protocol-type
   :source-type
   :file-type
   :metric-type
   :run-mode-type
   :extraction-method-type
   :material-type

   :image-type
   :image-instance
   :image-version
   :image-task

   :biological-source
   :biological-source-reference-file

   :input-data-file-set
   :input-data-file

   :benchmark-type
   :benchmark-instance
   :task
   :task_expanded_fields])

(deftest migrate

  (testing "-main"
    (do (drop-tables)
        (migrate/migrate "tmp/input_data")
        (dorun (for [table-name tables]
                 (is (not (= 0 (table-length table-name))) (str table-name)))))))
