(ns helper.validation
  (:require
    [clojure.test         :refer :all]
    [helper.http-response :as resp]))

(defn has-image-metadata [response]
  (resp/dispatch-response-body-test #(:image %) response))

(defn is-valid-image? [image]
  (dorun
    (for [k [:name :sha256 :task :type :version]]
      (do (is (contains? image k))
          (is (not (nil? (k image))) (str k " is nil in " image))))))
