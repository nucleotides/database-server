(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [compojure.handler  :refer [site]]
            [clojure.data.json  :as json]
            [ring.mock.request  :as mock]

            [nucleotides.database.connection  :as con]
            [nucleotides.database.load        :as db]
            [nucleotides.api.core             :as app]
            [helper                           :as help]

            ))

(help/silence-logging!)

(def database-client (con/create-connection))

(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (site (app/api database-client))]
     (hnd (mock/request method url params))))
  ([method url]
   (request method url {})))

(deftest app

  (testing "GET /events/show.json"
    (let [f #(request :get "/benchmarks/show.json")]

      (testing "with a single benchmark entry"
        (let [_ (help/load-fixture "a_single_benchmark")
              {:keys [status body]} (f)]
          (is (= 200 status))
          (is (= 1 (count (json/read-str body)))))))))

