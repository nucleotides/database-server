(ns helper.http-response
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [helper.database    :as db]
            [helper.fixture     :as fix]))

(defn dispatch-response-body-test
  ([f path response]
   (let [body (if (isa? (class (:body response)) String)
                (clojure.walk/keywordize-keys (json/read-str (:body response)))
                (:body response))]
     (f (get-in body path))))
  ([f response]
   (dispatch-response-body-test f [] response)))




(defn is-ok-response [response]
  (is (contains? #{200 201} (:status response))))

(defn is-client-error-response [response]
  (is (contains? #{404 422} (:status response))))

(defn has-header [response header]
  (is (contains? (:headers response) header)))

(defn has-body [body]
  #(is (= body (:body %))))

(defn is-empty-body [response]
  (is (empty? (json/read-str (:body response)))))

(defn is-not-empty-body [response]
  (is (not (empty? (json/read-str (:body response))))))

(defn is-not-complete [response]
  (let [f #(is (= false (:complete %)))]
    (dispatch-response-body-test f [] response)))

(defn is-complete [response]
  (let [f #(is (= true (:complete %)))]
    (dispatch-response-body-test f [] response)))

(defn file-entry [[type_ url sha256 :as entry]]
  (into {} (map vector [:type :url :sha256] entry)))

(defn contains-file-entries [response path & entries]
  (let [files (set (get-in response path))]
    (is (not (empty? files)))
    (dorun
      (for [f files]
        (for [key_ [:url :type :sha256]]
          (is (contains? f key_)))))
    (dorun
      (for [entry entries]
        (is (contains? files entry))))))

(defn contains-event-entries [response path & entries]
  (let [events (->> (get-in response path)
                    (map #(dissoc % :created_at :id))
                    (set))]
    (dorun
      (for [e entries]
        (is (contains? events e))))))

(defn test-response [{:keys [api-call tests fixtures]}]
  (db/empty-database)
  (apply fix/load-fixture fixtures)
  (let [response (api-call)]
    (dorun
      (for [t tests] (t response)))))

(defn does-http-body-contain
  ([ks path]
   (fn [response]
     (let [f #(dorun
                (for [k ks]
                  (is (contains? % k))))]
       (dispatch-response-body-test f path response))))
  ([ks]
   (does-http-body-contain ks [])))

(defn does-http-body-not-contain [ks response]
  (let [not-contains? (complement contains?)
        f #(dorun
             (for [k ks]
               (is (not-contains? % k))))]
    (dispatch-response-body-test f response)))
