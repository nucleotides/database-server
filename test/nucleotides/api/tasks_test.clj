(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.tasks            :as task]
            [helper.fixture                   :as fix]))

(deftest nucleotides.api.tasks

  (testing "#show"

    (testing "getting tasks for an incomplete benchmark"
      (let [_                     (fix/load-fixture "a_single_incomplete_task")
            {:keys [status body]} (task/show {:connection (con/create-connection)} {})]
        (is (= 200 status))
        (is (= 1 (count body)))
        (dorun
          (for [k [:id :input_url :input_md5 :task_type
                   :image_name :image_sha256 :image_task :image_type]]
            (is (contains? (first body) k))))))))
