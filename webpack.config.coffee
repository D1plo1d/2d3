path = require "path"

module.exports =
  entry:
    "examples/example_1": "./examples/example_1.coffee"
  devtool: "inline-source-map"
  output:
    path: "."
    filename: "[name].js"
  resolve:
    alias:
      mechly: path.join(__dirname, "src", "javascripts", "mechly.coffee")
  module:
    loaders: [
      {
        test: /\.css$/
        loader: "style!css"
      }
      {
        test: /\.styl$/
        loader: "style-loader!css-loader!stylus-loader"
      }
      {
        test: /\.coffee$/
        loader: "coffee"
      }
      {
        test: /\.woff($|\?)|\.woff2($|\?)|\.ttf($|\?)|\.eot($|\?)|\.svg($|\?)/,
        loader: "url-loader"
      }
    ]
