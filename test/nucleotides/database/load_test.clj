(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.java.jdbc               :as db]
            [helper                          :as help]
            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(use-fixtures :each (fn [f] (help/empty-database) (f)))

(defn run-loader [f file]
  (f (con/create-connection) (help/fetch-test-data file)))

(deftest load-image-types
  (testing "with a single image type entry"
    (let [ _       (run-loader ld/image-types :image)
          entries  (help/image-types)]
      (is (= 1 (count entries))))))


(deftest load-data-types
  (testing "with a single data entry"
    (let [_        (run-loader ld/data-types :data)
          entries  (help/data-types)]
      (is (= 1 (count entries))))))
