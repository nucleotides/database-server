(ns nucleotides.database.metadata-test
  (:require [clojure.test     :refer :all]
            [helper.database  :refer :all]

            [nucleotides.database.files    :as files]
            [nucleotides.database.metadata :as mtd]))

(deftest save-metadatum!
  (let [[table-name entries] (first (:cv (files/load-data-files "tmp/input_data")))]
    (do (empty-database)
        (mtd/save-metadatum! table-name (first entries))
        (is (not (empty? (metadata-entries table-name)))))))


(deftest load-all-metadata
  (let [data (:cv (files/load-data-files "tmp/input_data"))]
    (do (empty-database)
        (mtd/load-all-metadata data)
        (dorun
          (for [table-name (keys data)]
            (is (not (empty? (metadata-entries table-name)))))))))
