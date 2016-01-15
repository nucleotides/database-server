(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.walk                    :as walk]
            [clojure.pprint                  :as pp]
            [clojure.java.jdbc               :as db]
            [clojure.set                     :as st]

            [helper.database  :refer :all]
            [helper.fixture   :refer :all]

            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(use-fixtures :each (fn [f] (empty-database) (f)))

(defn run-loader [f file]
  (f (con/create-connection) (fetch-test-data file)))

(deftest load-image-types
  (let [f  #(run-loader ld/image-types :image)]

    (testing "loading with into an empty database"
      (do (f)
          (is (= 4 (table-length :image-type)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 4 (table-length :image-type)))))))


(deftest load-image-instances
  (let [_  (run-loader ld/image-types :image)
        f  #(run-loader ld/image-instances :image)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 5 (table-length :image-instance)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 5 (table-length :image-instance)))))))


(deftest load-image-tasks
  (let [_  (run-loader ld/image-types :image)
        _  (run-loader ld/image-instances :image)
        f  #(run-loader ld/image-tasks :image)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 6 (table-length :image-instance-task)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 6 (table-length :image-instance-task)))))))


(deftest load-data-sets
  (let [f  #(run-loader ld/data-sets :data)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 1 (table-length :data-set)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 1 (table-length :data-set)))))))


(deftest load-data-records
  (let [_  (run-loader ld/data-sets :data)
        f  #(run-loader ld/data-records :data)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 3 (table-length :data-record)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 3 (table-length :data-record)))))))


(deftest load-benchmark-types
  (let [_  (run-loader ld/data-sets :data)
        _  (run-loader ld/image-types :image)
        f  #(run-loader ld/benchmark-types :benchmark_type)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 2 (table-length :benchmark-type)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 2 (table-length :benchmark-type)))))))

(deftest load-benchmark-instances
  (let [_  (run-loader ld/data-sets :data)
        _  (run-loader ld/data-records :data)
        _  (run-loader ld/image-types :image)
        _  (run-loader ld/image-instances :image)
        _  (run-loader ld/image-tasks :image)
        _  (run-loader ld/benchmark-types :benchmark_type)
        f  #(ld/rebuild-benchmark-task (con/create-connection))]

    (testing "loading into an empty database"
      (do (f)
          (is (not (= 0 (table-length :benchmark-instance))))
          (is (not (= 0 (table-length :task))))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (not (= 0 (table-length :benchmark-instance))))
          (is (not (= 0 (table-length :task))))))))

(deftest load-metric-types
  (let [f  #(run-loader ld/metric-types :metric_type)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 2 (table-length :metric-type)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 2 (table-length :metric-type)))))))
