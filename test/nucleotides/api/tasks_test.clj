(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [helper.database                  :refer :all]
            [helper.fixture                   :refer :all]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]))


(defn contains-task-entries [task]
  (dorun
    (for [key_ [:id :input_url :input_md5 :task_type
                :image_name :image_sha256 :image_task :image_type]]
      (is (contains? task key_)))))

(use-fixtures :once (fn [f]
                      (empty-database)
                      (load-fixture :metadata :input-data-source :input-data-file-set
                                    :input-data-file :image-instance :benchmarks :tasks)
                      (f)))

(deftest nucleotides.api.tasks

  (testing "#get"

    (testing "an incomplete produce task by its ID"
      (let [{:keys [status body]} (task/lookup {:connection (con/create-connection)} 1 {})]
        (is (= 200 status)))))


  (comment (testing "#show"

    (testing "getting tasks for an incomplete benchmark"
      (let [{:keys [status body]} (task/show {:connection (con/create-connection)} {})]
        (is (= 200 status))
        (is (= 1 (count body)))
        (contains-task-entries (first body)))))))
