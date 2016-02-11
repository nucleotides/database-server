(ns nucleotides.api.events-test
  (:require [clojure.test          :refer :all]
            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.events           :as ev]))

(defn test-create-event [event]
  (resp/test-response
    {:api-call #(ev/create {:connection (con/create-connection)} {:body event})
     :fixtures fix/base-fixtures
     :tests    [resp/is-ok-response
                #(resp/has-header % "Location")]}))

(defn test-get-event [{:keys [event-id fixtures files]}]
  (resp/test-response
    {:api-call #(ev/lookup {:connection (con/create-connection)} event-id {})
     :fixtures (concat fix/base-fixtures fixtures)
     :tests    [resp/is-ok-response
                (resp/does-http-body-contain [:task :success :created_at :metrics])
                #(apply resp/contains-file-entries % [:body :files] (map resp/file-entry files))]}))

(deftest nucleotides.api.events

  (testing "#create"

    (testing "with an unsuccessful produce event"
      (test-create-event (mock-event :produce :failure))
      (is (= 1 (db/table-length "event")))
      (is (= "log_file" (:sha256 (last (db/table-entries "file_instance"))))))

    (testing "with an unsuccessful produce event"
      (test-create-event (mock-event :evaluate :success))
      (is (= 1 (db/table-length "event")))
      (is (= 2 (db/table-length "metric_instance")))
      (is (= "log_file" (:sha256 (last (db/table-entries "file_instance")))))))

  (testing "#get"

    (testing "an unsuccessful produce event"
      (test-get-event
        {:event-id 1
         :fixtures [:unsuccessful-product-event]}))

    (testing "a successful evaluate event"
      (test-get-event
        {:event-id 1
         :fixtures [:successful-evaluate-event]}))))
