(ns helper.http-response
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [helper.database    :as db]
            [helper.fixture     :as fix]
            ))

(defn is-ok-response [response]
  (is (contains? #{200 201} (:status response))))

(defn has-header [response header]
  (is (contains? (:headers response) header)))

(defn has-body-entry [response & ks]
  (let [body (json/read-str (:body response))]
    (dorun
      (for [k ks]
        (is (contains? body k))))))

(defn is-empty-body [response]
  (is (empty? (json/read-str (:body response)))))

(defn is-not-empty-body [response]
  (is (not (empty? (json/read-str (:body response))))))

(defn test-response [{:keys [api-call tests fixtures]}]
  (db/empty-database)
  (apply fix/load-fixture fixtures)
  (let [response (api-call)]
    (dorun
      (for [t tests] (t response)))))

(defn does-http-body-contain [ks response]
  (let [body (:body response)]
    (dorun
      (for [k ks]
        (is (contains? body k))))))
