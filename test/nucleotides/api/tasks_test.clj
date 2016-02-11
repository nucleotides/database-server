(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [helper.http-response             :as resp]
            [helper.fixture                   :as fix]
            [helper.image                     :as image]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]))


(def contains-task-entries
  (resp/does-http-body-contain [:id :benchmark :type :complete :image :inputs]))

(defn contains-task-files [file-list]
  (let [path  [:body :inputs]
        files (map resp/file-entry file-list)]
    (fn [response]
      (apply resp/contains-file-entries response path files))))

(defn test-get-task [{:keys [task-id extra-fixtures files]}]
  (resp/test-response
    {:api-call #(task/lookup {:connection (con/create-connection)} task-id {})
     :fixtures (concat fix/base-fixtures extra-fixtures)
     :tests    [resp/is-ok-response
                image/has-image-metadata
                contains-task-entries
                (contains-task-files files)]}))

(defn test-show-tasks [{:keys [extra-fixtures expected]}]
  (resp/test-response
    {:api-call (partial task/show {:connection (con/create-connection)} {})
     :fixtures (concat fix/base-fixtures extra-fixtures)
     :tests    [resp/is-ok-response
                #(is (= (sort (:body %)) (sort expected)))]}))

(deftest nucleotides.api.tasks

  (testing "#get"
    (let [f #(partial task/lookup {:connection (con/create-connection)} % {})]

      (testing "an incomplete produce task by its ID"
        (test-get-task
          {:task-id 1
           :files [["short_read_fastq" "s3://reads" "c1f0f"]]}))

      (testing "an incomplete evaluate task with no produce files by its ID"
        (test-get-task
          {:task-id 2
           :files [["reference_fasta" "s3://ref" "d421a4"]]}))

      (testing "an incomplete evaluate task with no produce files by its ID"
        (test-get-task
          {:task-id 2
           :files [["reference_fasta" "s3://ref" "d421a4"]
                   ["contig_fasta"    "s3://contigs" "f7455"]]
           :extra-fixtures [:successful-product-event]}))))

  (testing "#show"

    (testing "getting all incomplete tasks"
      (test-show-tasks {:expected [1 3 5 7 9 11]}))

    (testing "getting incomplete tasks with an unsuccessful produce task"
      (test-show-tasks
        {:extra-fixtures [:unsuccessful-product-event]
         :expected       [1 3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce task"
      (test-show-tasks
        {:extra-fixtures [:successful-product-event]
         :expected       [2 3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce task"
      (test-show-tasks
        {:extra-fixtures [:successful-product-event :successful-evaluate-event]
         :expected       [3 5 7 9 11]}))))
