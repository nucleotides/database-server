(ns nucleotides.util
  (:require [taoensso.timbre :as log]))

(defn get-env-var [v]
  (let [value (System/getenv v)]
    (if (nil? value)
      (do
        (log/fatal (str "Unbound environment variable: " v))
        (System/exit 1))
      (do
        (log/info (str "Using environment variable: " v "=" value))
        value))))

