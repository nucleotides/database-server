(ns nucleotides.api.events-test
  (:require [clojure.test          :refer :all]
            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.events           :as event]))

(defn test-create-event [params]
  (resp/test-response
    {:api-call #(event/create {:connection (con/create-connection)} {:params params})
     :fixtures fix/base-fixtures
     :tests    [resp/is-ok-response]}))

(defn test-get-event [{:keys [event-id fixtures]}]
  (resp/test-response
    {:api-call #(event/lookup {:connection (con/create-connection)} event-id {})
     :fixtures (concat fix/base-fixtures fixtures)
     :tests    [resp/is-ok-response
                (partial resp/does-http-body-contain [:task :success :created_at])]}))

(deftest nucleotides.api.events

  (testing "#create"
     (testing "with an unsuccessful produce event"
       (test-create-event (mock-event :produce :failure))))

  (testing "#get"
    (testing "an unsuccessful produce event"
      (test-get-event
        {:event-id 1
         :fixtures [:unsuccessful-product-event]}))))
