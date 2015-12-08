(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [ring.mock.request  :as mock]

            [nucleotides.database.connection  :as con]
            [nucleotides.database.load        :as db]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.core             :as app]
            [helper                           :as help]))


(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (md/middleware (app/api {:connection (con/create-connection)}))]
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

  (testing "GET /tasks/show.json"
    (let [f (comp (partial request :get) (partial str "/tasks/show.json"))]

      (let [_   (help/load-fixture "a_single_incomplete_task")
            res (f)]
        (is-ok-response res)
        (is-not-empty-body res)))))
