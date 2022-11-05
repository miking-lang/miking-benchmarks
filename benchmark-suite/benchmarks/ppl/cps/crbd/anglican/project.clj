(defproject crbd "0.1.0-SNAPSHOT"
  :dependencies [[anglican "1.1.0"]
                 [org.clojure/tools.cli "1.0.214"]
                 [org.clojure/tools.logging "1.2.4"]]
  :main ^:skip-aot crbd.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
