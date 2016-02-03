(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [helper.http-response             :as resp]
            [helper.fixture                   :as fix]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]))


(defn contains-task-entries [response]
  (let [body (:body response)]
    (dorun
      (for [key_ [:id :benchmark :task_type :image_name :image_sha256 :image_task :image_type]]
        (is (contains? body key_))))
    (is (not (contains? body :benchmark_instance_id)))))

(defn contains-file-entries [response & entries]
  (let [files (set (get-in response [:body :files]))]
    (is (not (empty? files)))
    (dorun
      (for [f files]
        (for [key_ [:url :type :sha256]]
          (is (contains? f key_)))))
    (dorun
      (for [entry entries]
        (is (contains? files entry))))))

(defn file-entry [[type_ url sha256 :as entry]]
  (into {} (map vector [:type :url :sha256] entry)))

(defn test-task-response [{:keys [task-id extra-fixtures files]}]
  (resp/test-response
    {:api-call #(task/lookup {:connection (con/create-connection)} task-id {})
     :fixtures (concat fix/base-fixtures extra-fixtures)
     :tests    [resp/is-ok-response
                contains-task-entries
                #(apply contains-file-entries % (map file-entry files))]}))

(deftest nucleotides.api.tasks

  (testing "#get"
    (let [f #(partial task/lookup {:connection (con/create-connection)} % {})]

      (testing "an incomplete produce task by its ID"
        (test-task-response {:task-id 1}))

      (testing "an incomplete evaluate task with no produce files by its ID"
        (test-task-response
          {:task-id 2
           :files [["reference_fasta" "s3://ref" "d421a4"]]}))

      (testing "an incomplete evaluate task with no produce files by its ID"
        (test-task-response
          {:task-id 2
           :files [["reference_fasta" "s3://ref" "d421a4"]
                   ["contig_fasta"    "s3://contigs" "f7455"]]
           :extra-fixtures [:successful-product-event]}))))

  (comment (testing "#show"

    (testing "getting tasks for an incomplete benchmark"
      (let [{:keys [status body]} (task/show {:connection (con/create-connection)} {})]
        (is (= 200 status))
        (is (= 1 (count body)))
        (contains-task-entries (first body)))))))
