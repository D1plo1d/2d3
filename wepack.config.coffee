path = require "path"

module.exports =
  entry:
    # jsx: "./examples/jsx/example.jsx"
    coffeescript: "./examples/coffeescript/example.coffee"
  devtool: "inline-source-map"
  output:
    path: path.join _dirname, "dist"
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
