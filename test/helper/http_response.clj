(ns helper.http-response
  (:require [clojure.test       :refer :all]
            [helper.validation  :refer :all]
            [clojure.core.match :refer [match]]

            [clojure.data.csv   :as csv]
            [clojure.data.json  :as json]
            [helper.database    :as db]
            [helper.event       :as evt]
            [helper.fixture     :as fix]))

(defn parse-csv [raw-csv]
  (let [[header & rows] (csv/read-csv raw-csv)]
    (map #(zipmap header %) rows)))

(defn parse-response-body
  "Converts the body to a clojure object depending on the `Content-Type` header"
  [response]
  (let [response-body  (:body response)
        content-type   (->> (get-in response [:headers "Content-Type"])
                            (re-find #"\w+\/(json|csv)")
                            (last))]

    (match [(class response-body) content-type]
           [String "json"] (clojure.walk/keywordize-keys (json/read-str response-body))
           [String "csv"]  (parse-csv response-body)
           :else           response-body)))


(defn dispatch-response-body-test
  "Given a http response, executes the given function `f` on the content
  at the specified `path` within the parsed body of the returned response."
  ([f path response]
   (let [parsed-body (parse-response-body response)
         content (get-in parsed-body path)]
     (is (not (nil? content)) (str "No content found for " path " in: \n" parsed-body))
     (f content)))
  ([f response]
   (dispatch-response-body-test f [] response)))

(defn is-not-empty-at
  "Creates a function which given a http response ensures the collection
  at the specified path is not empty"
  [path]
  (let [f #(is (not (empty? %)) (str "Collection at " path " is empty"))]
    (partial dispatch-response-body-test f path)))

(defn contains-entries-at?
  "Creates a function which given a http response ensures the collection
  at the specified path contains the given entries"
  [path entries]
  (partial dispatch-response-body-test
           (fn [xs]
             (let [coll (into #{} xs)
                   f    #(is (contains? coll %))]
               (dorun (map f entries))))
           path))

(defn is-length-at?
  "Creates a function which given a http response ensures the collection
  at the specified path contains the expected number of entires"
  ([length]
   (is-length-at? [] length))
  ([path length]
   (let [f #(is (= length (count %))
                (str "Length should be " length ": " %))]
     (partial dispatch-response-body-test f path))))


(defn contains-event-entries [path entries]
  (let [f (fn [events]
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
  (partial dispatch-response-body-test #(is (empty? %))))

(defn is-not-empty-body [response]
  (partial dispatch-response-body-test #(is (not (empty? %)))))

(defn is-complete? [state]
  (partial dispatch-response-body-test #(is (= % state)) [:complete]))

(defn file-entry [entry]
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
