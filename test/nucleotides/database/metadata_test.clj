(ns nucleotides.database.metadata-test
  (:require [clojure.test     :refer :all]
            [helper.database  :refer :all]
            [helper.fixture   :refer :all]

            [nucleotides.database.files    :as files]
            [nucleotides.database.metadata :as mtd]))

(deftest save-metadatum!
  (let [[table-name entries] (first (:cv (files/load-data-files "tmp/input_data")))]
    (do (empty-database)
        (mtd/save-metadatum! table-name (first entries))
        (is (not (empty? (metadata-entries table-name)))))))
