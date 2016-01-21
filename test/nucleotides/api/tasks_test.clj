(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]
            [helper.fixture                   :as fix]))

(deftest nucleotides.api.tasks

  (defn contains-task-entries [task]
    (dorun
      (for [key_ [:id :input_url :input_md5 :task_type
                  :image_name :image_sha256 :image_task :image_type]]
        (is (contains? task key_)))))


  (testing "#show"

    (testing "getting tasks for an incomplete benchmark"
      (let [_                     (fix/load-fixture "a_single_incomplete_task")
            {:keys [status body]} (task/show {:connection (con/create-connection)} {})]
        (is (= 200 status))
        (is (= 1 (count body)))
        (contains-task-entries (first body)))))


  (testing "#get"

    (testing "finding a task by its ID"
      (let [_                     (fix/load-fixture "a_single_incomplete_task")
            {:keys [status body]} (task/lookup {:connection (con/create-connection)} 1 {})]
        (is (= 200 status))
        (contains-task-entries body)))))
