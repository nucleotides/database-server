(ns nucleotides.api.events-test
  (:require [clojure.test                     :refer :all]
            [nucleotides.database.connection  :as con]
            [clojure.data.json                :as json]
            [nucleotides.api.events           :as event]
            [helper                           :as help]))

(def create
  #(event/create {:connection (con/create-connection)} {:params %}))

(def valid-event
  {:task          1
   :success       true
   :log_file_url  "s3://url"
   :file_url      "s3://url"})

(deftest nucleotides.api.events

  (testing "#create"

    (testing "create an event"
      (let [_                        (help/load-fixture "a_single_incomplete_task")
            {:keys [status headers]} (create valid-event)]
        (is (= 201 status))
        (is (contains? headers "Location"))
        (is (= 1 (help/table-length "event")))))))
