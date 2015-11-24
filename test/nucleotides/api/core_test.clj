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

(defn is-empty-body [response]
  (is (empty? (json/read-str (:body response)))))

(defn is-not-empty-body [response]
  (is (not (empty? (json/read-str (:body response))))))

(deftest app

  (testing "GET /benchmarks/show.json"
    (let [f (comp (partial request :get) (partial str "/benchmarks/show.json"))]

      (let [_ (help/load-fixture "a_single_benchmark_with_completed_product")]

        (let [response (f "?product=true")]
          (is-ok-response response)
          (is-not-empty-body response))

        (let [response (f "?product=false")]
          (is-ok-response response)
          (is-empty-body response)))

      (let [_ (help/load-fixture "a_single_benchmark_with_completed_evaluation")]

        (let [response (f)]
          (is-ok-response response)
          (is-not-empty-body response))

        (let [response (f "?product=true")]
          (is-ok-response response)
          (is-not-empty-body response))

        (let [response (f "?product=false")]
          (is-ok-response response)
          (is-empty-body response))

        (let [response (f "?evaluation=true")]
          (is-ok-response response)
          (is-not-empty-body response))

        (let [response (f "?product=true&evaluation=false")]
          (is-ok-response response)
          (is-empty-body response)))))

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
        (is (= "1" (:body response))))))

  (testing "GET /benchmarks/:id"
    (let [f #(request :get (str "/benchmarks/" %))
          _ (help/load-fixture "a_single_benchmark")
          response (f "2f221a18eb86380369570b2ed147d8b4")]
        (is-ok-response response)
        (is (not (empty? (json/read-str (:body response))))))))
