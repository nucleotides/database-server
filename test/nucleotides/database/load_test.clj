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

(use-fixtures :each (fn [f] (help/empty-database) (f)))

(defn run-loader [f file]
  (f (con/create-connection) (help/fetch-test-data file)))

(deftest load-image-types
  (let [_  (run-loader ld/image-types :image)]
    (is (= 4 (help/table-length :image-type)))))

(deftest load-image-instances
  (let [_  (run-loader ld/image-types :image)
        _  (run-loader ld/image-instances :image)]
    (is (= 5 (help/table-length :image-instance)))))

(deftest load-image-instances
  (let [_  (run-loader ld/image-types :image)
        _  (run-loader ld/image-instances :image)
        _  (run-loader ld/image-tasks :image)]
    (is (= 6 (help/table-length :image-instance-task)))))

(deftest load-data-sets
  (let [_  (run-loader ld/data-sets :data)]
    (is (= 1 (help/table-length :data-set)))))

(deftest load-data-records
  (let [_  (run-loader ld/data-sets :data)
        _  (run-loader ld/data-records :data)]
    (is (= 3 (help/table-length :data-record)))))

(deftest load-benchmark-types
  (let [_  (run-loader ld/data-sets :data)
        _  (run-loader ld/image-types :image)
        _  (run-loader ld/benchmark-types :benchmark_type)]
    (is (= 2 (help/table-length :benchmark-type)))))

(deftest load-benchmark-instances
  (let [_  (run-loader ld/data-sets :data)
        _  (run-loader ld/data-records :data)
        _  (run-loader ld/image-types :image)
        _  (run-loader ld/image-instances :image)
        _  (run-loader ld/image-tasks :image)
        _  (run-loader ld/benchmark-types :benchmark_type)
        _  (ld/rebuild-benchmark-instance (con/create-connection))]
    (is (not (= 0 (help/table-length :benchmark-instance))))))

(deftest load-metric-types
  (let [_  (run-loader ld/metric-types :metric_type)]
    (is (= 2 (help/table-length :metric-type)))))
