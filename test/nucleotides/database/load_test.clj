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
    (let [data    [{:image_type      "type"
                    :description     "description"
                    :image_instances {:image "image/name"
                                      :tasks ["default" "careful"]}}]

          _        (run-loader ld/image-types data)
          entries  (help/image-types)]
      (is (= 1 (count entries))))))


(deftest load-data-types
  (testing "with a single data entry"
    (let [data     [{:name         "data_name"
                     :library      "protocol_type"
                     :type         "source_type"
                     :description  "description"
                     :entries      []}]
          _        (run-loader ld/data-types data)
          entries  (help/data-types)]
      (is (= 1 (count entries))))))
