(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.walk                    :as walk]
            [clojure.pprint                  :as pp]
            [clojure.java.jdbc               :as sql]
            [clojure.set                     :as st]

            [com.rpl.specter          :refer :all]

            [helper.database  :refer :all]
            [helper.fixture   :refer :all]

            [nucleotides.database.migrate    :as mg]
            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(use-fixtures :each (fn [f] (empty-database) (f)))

(def input-data
  (mg/load-data-files (test-directory :data)))

(defn run-loader [f data-key]
  (f (con/create-connection) (data-key input-data)))

(defn test-data-loader [{:keys [loader table fixtures]}]
  (testing "loading with into an empty database"
    (do (apply load-fixture fixtures)
        (loader (con/create-connection))
        (is (not (empty? (table-entries table))))))

  (testing "reloading the same data"
    (do (apply load-fixture fixtures)
        (loader (con/create-connection))
        (loader (con/create-connection))
        (is (not (empty? (table-entries table)))))))

(deftest load-metadata-types
  (dorun
    (for [data-key [:platform :file :metric :product :protocol :source]]
      (test-data-loader
        {:fixtures []
         :loader   #(ld/metadata-types % data-key (data-key input-data))
         :table    (str (name data-key) "-type")}))))

(deftest load-input-data-source
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/input-data-sources % (:data-source input-data))
     :table    :input-data-source}))

(deftest load-input-data-reference-files
  (test-data-loader
    {:fixtures [:metadata :input-data-source]
     :loader   #(ld/input-data-source-files % (:data-source input-data))
     :table    :input-data-source-reference-file}))

(deftest load-input-data-set
  (test-data-loader
    {:fixtures [:metadata :input-data-source]
     :loader   #(ld/input-data-file-set % (:data-file input-data))
     :table    :input-data-file-set}))

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
        f  #(run-loader ld/benchmark-types :benchmark-type)]

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
        _  (run-loader ld/benchmark-types :benchmark-type)
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
