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

(defn test-data-loader [{:keys [loader tables fixtures]}]

    (testing "loading with into an empty database"
      (do (apply load-fixture fixtures)
          (loader (con/create-connection))
          (dorun
            (for [t tables]
              (is (not (empty? (table-entries t))))))))

    (testing "reloading the same data"
      (do (apply load-fixture fixtures)
          (loader (con/create-connection))
          (loader (con/create-connection))
          (dorun
            (for [t tables]
              (is (not (empty? (table-entries t)))))))))

(deftest load-metadata-types
  (dorun
    (for [data-key [:platform :file :metric :product :protocol :source :image]]
      (test-data-loader
        {:fixtures []
         :loader   #(ld/metadata-types % data-key (data-key input-data))
         :tables   [(str (name data-key) "-type")]}))))

(deftest load-input-data-source
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/input-data-sources % (:data-source input-data))
     :tables   [:input-data-source]}))

(deftest load-input-data-reference-files
  (test-data-loader
    {:fixtures [:metadata :input-data-source]
     :loader   #(ld/input-data-source-files % (:data-source input-data))
     :tables   [:input-data-source-reference-file]}))

(deftest load-input-data-set
  (test-data-loader
    {:fixtures [:metadata :input-data-source]
     :loader   #(ld/input-data-file-set % (:data-file input-data))
     :tables   [:input-data-file-set]}))

(deftest load-input-data-file
  (test-data-loader
    {:fixtures [:metadata :input-data-source :input-data-file-set]
     :loader   #(ld/input-data-files % (:data-file input-data))
     :tables   [:input-data-file]}))

(deftest load-image-instances
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/image-instances % (:image-instance input-data))
     :tables   [:image-instance :image-instance-task]}))

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
  (let [_  (load-fixture :metadata)
        _  (run-loader ld/data-sets :data)
        f  #(run-loader ld/benchmark-types :benchmark-type)]

    (testing "loading into an empty database"
      (do (f)
          (is (= 2 (table-length :benchmark-type)))))

    (testing "reloading the same data"
      (do (f)
          (f)
          (is (= 2 (table-length :benchmark-type)))))))

(deftest load-benchmark-instances
  (let [_  (load-fixture :metadata :image-instance)
        _  (run-loader ld/data-sets :data)
        _  (run-loader ld/data-records :data)
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
