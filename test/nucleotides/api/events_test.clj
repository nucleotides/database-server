(ns nucleotides.api.events-test
  (:require [clojure.test          :refer :all]
            [helper.event          :refer :all]
            [helper.fixture        :refer :all]
            [helper.database       :refer :all]
            [helper.http-response  :refer :all]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.events           :as event]))

(def create
  #(event/create {:connection (con/create-connection)} {:params %}))

(deftest nucleotides.api.events

  (testing "#create"

    (testing "with a successful event"
      (let [_        (load-fixture "a_single_incomplete_task")
            response (create (mock-event :success))
            {:keys [status headers]} response ]
        (is-ok-response response)
        (has-header response "Location")
        (is (= 1 (table-length "event")))))

    (testing "with an unsuccessful event"
      (let [_        (load-fixture "a_single_incomplete_task")
            response (create (mock-event :failure))]
        (is-ok-response response)
        (has-header response "Location")
        (is (= 1 (table-length "event")))))))
