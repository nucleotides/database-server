(ns helper.http-response
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [helper.database    :as db]
            [helper.event       :as evt]
            [helper.fixture     :as fix]))

(defn dispatch-response-body-test
  "Given a http response, executes the given function `f` on the content
  at the specified `path` within the returned body of the response."
  ([f path response]
   (let [body     (if (isa? (class (:body response)) String)
                    (clojure.walk/keywordize-keys (json/read-str (:body response)))
                    (:body response))
         content  (get-in body path)]
     (is (not (nil? content)) (str "No content found for " path " in: \n" body))
     (f content)))
  ([f response]
   (dispatch-response-body-test f [] response)))

(defn contains-file-entries [path entries]
  (let [test-empty    #(is (not (empty? %)))
        test-valid    #(dorun
                         (for [f %]
                           (for [key_ [:url :type :sha256]]
                             (is (contains? f key_)))))
        test-entries  #(dorun
                         (for [e entries]
                           (is (contains? % e))))
        f (fn [xs]
            (let [files (set xs)]
              (do (test-empty files)
                  (test-valid files)
                  (test-entries files))))]
    (partial dispatch-response-body-test f path)))

(defn contains-event-entries [path entries]
  (let [f (fn [events]
            (dorun (map evt/is-valid-event? events))
            (dorun (map (partial evt/has-event? events) entries)))]
   (partial dispatch-response-body-test f path)))

(defn is-ok-response [response]
  (is (contains? #{200 201} (:status response))))

(defn is-client-error-response [response]
  (is (contains? #{404 422} (:status response))))

(defn has-header [response header value]
  (let [hdrs (:headers response)]
    (is (contains? hdrs header))
    (is (= value (hdrs header)))))

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
