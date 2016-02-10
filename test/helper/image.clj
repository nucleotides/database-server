(ns helper.image
  (:require
    [clojure.test         :refer :all]
    [helper.http-response :as resp]))

(defn has-image-metadata [response]
  (let [f #(dorun
             (for [k [:name :sha256 :task :type]]
               (is (contains? (:image %) k))))]
    (resp/dispatch-response-body-test f response)))
