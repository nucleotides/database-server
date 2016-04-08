(ns nucleotides.database.files-test
  (:require [clojure.test               :refer :all]
            [clojure.java.io            :as io]
            [nucleotides.database.files :as files]))

(deftest test-filename->keyword
  (let [file (->> (io/file "tmp/input_data/controlled_vocabulary")
                  (file-seq)
                  (last))]
    (is (= :source (files/filename->keyword file)))))


(deftest test-get-dataset-map

  (testing "on the controlled vocabulary directory"
    (let [dir     "tmp/input_data/controlled_vocabulary"
          inputs  (files/get-dataset-map dir)]
    (is (contains? inputs :source))
    (is (= (first (inputs :source))
           {:name "metagenome" :desc "A mixture of multiple genomes"}))))

  (testing "on the inputs directory"
    (let [dir     "tmp/input_data/inputs"
          inputs  (files/get-dataset-map dir)]
      (is (contains? inputs :image))
      (is (contains? inputs :benchmark))
      (is (not (contains? inputs :data)))))

  (testing "on the data directory"
    (let [dir     "tmp/input_data/inputs/data"
          inputs  (files/get-dataset-map dir)]
      (is (contains? inputs :amycolatopsis-sulphurea-dsm-46092)))))


(deftest test-load-data-files
  (let [dir     "tmp/input_data"
        inputs  (set (keys (files/load-data-files dir)))]
    (is (contains? inputs :cv))
    (is (contains? inputs :inputs))
    (is (contains? inputs :data))))
