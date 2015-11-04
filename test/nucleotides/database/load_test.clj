(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.walk                    :as walk]
            [clojure.pprint                  :as pp]
            [clojure.java.jdbc               :as db]
            [clojure.set                     :as st]
            [com.rpl.specter :refer :all]
            [helper                          :as help]
            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(use-fixtures :each (fn [f] (help/empty-database) (f)))

(defn run-loader [f file]
  (f (con/create-connection) (help/fetch-test-data file)))

(deftest load-image-types
  (let [_        (run-loader ld/image-types :image)
        entries  (help/image-types)]
    (is (= 2 (count entries)))))

(deftest load-data-types
  (let [_        (run-loader ld/data-types :data)
        entries  (help/data-types)]
    (is (= 1 (count entries)))))

(deftest load-data-instances
  (let [_        (run-loader ld/data-types :data)
        _        (run-loader ld/data-instances :data)
        entries  (help/data-instances)]
    (is (= 3 (count entries)))))

(deftest load-benchmark-types
  (let [_        (run-loader ld/data-types :data)
        _        (run-loader ld/image-types :image)
        _        (run-loader ld/benchmark-types :benchmark_type)
        entries  (help/benchmark-types)]
    (is (= 2 (count entries)))))
