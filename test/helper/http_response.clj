(ns helper.http-response
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [helper.database    :as db]
            [helper.fixture     :as fix]))

(defn is-ok-response [response]
  (is (contains? #{200 201} (:status response))))

(defn has-header [response header]
  (is (contains? (:headers response) header)))

(defn dispatch-response-body-test [f response]
  (let [body (if (isa? (class (:body response)) String)
               (clojure.walk/keywordize-keys (json/read-str (:body response)))
               (:body response))]
    (f body)))

(defn is-empty-body [response]
  (is (empty? (json/read-str (:body response)))))

(defn is-not-empty-body [response]
  (is (not (empty? (json/read-str (:body response))))))

(defn file-entry [[type_ url sha256 :as entry]]
  (into {} (map vector [:type :url :sha256] entry)))

(defn contains-file-entries [response & entries]
  (let [files (set (get-in response [:body :files]))]
    (is (not (empty? files)))
    (dorun
      (for [f files]
        (for [key_ [:url :type :sha256]]
          (is (contains? f key_)))))
    (dorun
      (for [entry entries]
        (is (contains? files entry))))))

(defn test-response [{:keys [api-call tests fixtures]}]
  (db/empty-database)
  (apply fix/load-fixture fixtures)
  (let [response (api-call)]
    (dorun
      (for [t tests] (t response)))))

(defn does-http-body-contain [ks response]
  (let [f #(dorun
             (for [k ks]
               (is (contains? % k))))]
    (dispatch-response-body-test f response)))
