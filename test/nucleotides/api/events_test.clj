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

(def lookup
  #(event/lookup {:connection (con/create-connection)} % {}))


(comment (deftest nucleotides.api.events

  (testing "#create"

    (testing "with a successful produce event"
      (let [_   (load-fixture "a_single_incomplete_task")
            res (create (mock-event :produce :success))]
        (is-ok-response res)
        (has-header res "Location")
        (is (= 1 (table-length "event")))))

    (testing "with an unsuccessful produce event"
      (let [_   (load-fixture "a_single_incomplete_task")
            res (create (mock-event :produce :failure))]
        (is-ok-response res)
        (has-header res "Location")
        (is (= 1 (table-length "event")))))

    (testing "with a successful evaluate event"
      (let [_   (load-fixture "a_single_incomplete_task")
            res (create (mock-event :evaluate :success))]
        (is-ok-response res)
        (has-header res "Location")
        (is (= 1 (table-length "event")))
        (is (= 2 (table-length "metric-instance"))))))

  (testing "#get"

    (testing "a product event"
      (let [_   (load-fixture "a_single_incomplete_task" "a_successful_product_event")
            res (lookup 1)]
        (is-ok-response res)
        (is (contains? (:body res) :id))))

    (testing "a product event"
      (let [_   (load-fixture "a_single_incomplete_task"
                              "a_successful_product_event"
                              "a_successful_evaluate_event")
            res (lookup 2)]
        (is-ok-response res)
        (is (contains? (:body res) :id))
        (is (contains? (:body res) :metrics)))))))

