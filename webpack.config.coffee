path = require "path"
ExtractTextPlugin = require('extract-text-webpack-plugin')

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
  plugins: [
    new ExtractTextPlugin 'app.css', allChunks: true
  ]
  worker: {
    output: {
      filename: "hash.worker.js",
      chunkFilename: "[id].hash.worker.js"
    }
  }
  module:
    loaders: [
      {
        test: /\.styl$/,
        loader: ExtractTextPlugin.extract('style',
          'css?modules&importLoaders=1&'+
          'localIdentName=[name]__[local]___[hash:base64:5]!stylus-loader'
        )
      }
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract('style',
          'css?modules&importLoaders=1&'+
          'localIdentName=[name]__[local]___[hash:base64:5]'
        )
      }
      {
        test: /\.coffee$/
        loader: "coffee"
      }
      {
        test: /\.jsx?$/
        exclude: /^(node_modules|dist|scripts)/
        loader: "babel?stage=0"
      }
      {
        test: /\.woff($|\?)|\.woff2($|\?)|\.ttf($|\?)|\.eot($|\?)|\.svg($|\?)/,
        loader: "url-loader"
      }
    ]
