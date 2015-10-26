(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.java.jdbc               :as db]
            [helper                          :as help]
            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(use-fixtures :each (fn [f] (help/empty-database) (f)))

(defn run-loader [f data]
  (f (con/create-connection) data))

(deftest load-image-types
  (testing "with a single image type entry"
    (let [data    [{"image_type"      "type"
                    "description"     "description"
                    "image_instances" {"image" "image/name"
                                       "tasks" ["default" "careful"]}}]
          entries (run-loader ld/image-types data)]
    (is (not (empty? entries)))
    (is (= 1 (count entries)))
    (is (= 1 (:id (first entries)))))))


(deftest load-data-types
  (testing "with a single data type entry"
    (let [data   [{"name"      "data_name"
                   "protocol"  "protocol_type"
                   "source"    "source_type"}]
          entries (run-loader ld/data-types data)]
    (is (not (empty? entries)))
    (is (= 1 (count entries)))
    (is (= 1 (:id (first entries)))))))
