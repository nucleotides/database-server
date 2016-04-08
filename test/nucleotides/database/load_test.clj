(ns nucleotides.database.load-test
  (:require [clojure.test     :refer :all]
            [helper.database  :refer :all]
            [helper.fixture   :refer :all]

            [nucleotides.database.files      :as files]
            [nucleotides.database.migrate    :as mg]
            [nucleotides.database.load       :as ld]
            [nucleotides.database.connection :as con]))

(def input-data
  (files/load-data-files "tmp/input_data"))

(defn test-data-loader [{:keys [loader tables fixtures]}]

    (testing "loading with into an empty database"
      (do (empty-database)
          (apply load-fixture fixtures)
          (loader)
          (dorun
            (for [t tables]
              (is (not (empty? (table-entries t))))))))

    (testing "reloading the same data"
      (do (empty-database)
          (apply load-fixture fixtures)
          (loader)
          (loader)
          (dorun
            (for [t tables]
              (is (not (empty? (table-entries t)))))))))

(deftest load-image-instances
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/image-instances (get-in input-data [:inputs :image]))
     :tables   [:image-instance :image-instance-task]}))

(deftest load-biological-sources
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/biological-sources (:biological-source input-data))
     :tables   [:biological-source]}))

(deftest load-biological-source-reference-files
  (test-data-loader
    {:fixtures [:metadata :biological-source]
     :loader   #(ld/biological-source-files (:biological-source input-data))
     :tables   [:biological-source-reference-file]}))

(deftest load-input-data-set
  (test-data-loader
    {:fixtures [:metadata :biological-source]
     :loader   #(ld/input-data-file-set (:file input-data))
     :tables   [:input-data-file-set]}))

(deftest load-input-data-file
  (test-data-loader
    {:fixtures [:metadata :biological-source :input-data-file-set]
     :loader   #(ld/input-data-files (:file input-data))
     :tables   [:input-data-file]}))

(deftest load-benchmark-types
  (test-data-loader
    {:fixtures [:metadata]
     :loader   #(ld/benchmark-types (:benchmark input-data))
     :tables   [:benchmark-type]}))

(deftest load-benchmark-data
  (test-data-loader
    {:fixtures [:metadata :biological-source :input-data-file-set :benchmark-type]
     :loader   #(ld/benchmark-data (:benchmark input-data))
     :tables   [:benchmark-data]}))

(deftest load-benchmark-instances
  (test-data-loader
    {:fixtures [:metadata :biological-source :input-data-file-set :input-data-file :assembly-image-instance :benchmark-type :benchmark-data]
     :loader   #(ld/populate-instance-and-task! {} {:connection (con/create-connection)})
     :tables   [:benchmark-instance :task]}))
