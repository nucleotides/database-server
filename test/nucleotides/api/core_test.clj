(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [compojure.handler  :refer [site]]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]
            [ring.mock.request  :as mock]

            [nucleotides.database.connection  :as con]
            [nucleotides.database.load        :as db]
            [nucleotides.api.core             :as app]
            [helper                           :as help]))


(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (site (app/api (con/create-connection)))]
     (hnd (mock/request method url params))))
  ([method url]
   (request method url {})))

(defn is-ok-response [response]
  (is (contains? #{200 201} (:status response))))

(deftest app

  (testing "GET /benchmarks/show.json"
    (let [f (comp (partial request :get) (partial str "/benchmarks/show.json"))
          _ (help/load-fixture "a_single_benchmark_with_completed_evaluation")]

      (let [response (f)]
        (is-ok-response response)
        (is (not (empty? (json/read-str (:body response))))))

      (let [response (f "?product=true")]
        (is-ok-response response)
        (is (not (empty? (json/read-str (:body response))))))

      (let [response (f "?evaluation=true")]
        (is-ok-response response)
        (is (not (empty? (json/read-str (:body response))))))

      (let [response (f "?product=true&evaluation=false")]
        (is-ok-response response)
        (is (empty? (json/read-str (:body response)))))))

  (testing "POST /benchmarks/"
    (let [f (partial request :post "/benchmarks/")
          _ (help/load-fixture "a_single_benchmark")
          params {:id              "2f221a18eb86380369570b2ed147d8b4"
                  :benchmark_file  "s3://url"
                  :log_file        "s3://url"
                  :event_type      "product"
                  :success         "true"}]
      (let [response (f params)]
        (is-ok-response response)
        (is (= "1" (:body response)))))))
