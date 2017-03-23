/* jshint strict:false */

module.exports = {
  options: {
    patterns: [
      {
        match: 'buildTimestamp',
        replacement: '<%= timestamp %>'
      }
    ]
  }, 
  
  "general": {
    files: [
      {
        expand: true, 
        cwd: 'src/general/html/', 
        src: [
          '**/*.*'
        ], 
        dest: "dist/general/html/"
      }
    ]
  }, 
  
  "heart-walk": {
    files: [
      {
        expand: true, 
        cwd: 'src/heart-walk/html/', 
        src: [
          '**/*.*'
        ], 
        dest: "dist/heart-walk/html/"
      }
    ]
  }, 
  
  "youth-markets": {
    files: [
      {
        expand: true, 
        cwd: 'src/youth-markets/html/', 
        src: [
          '**/*.*'
        ], 
        dest: "dist/youth-markets/html/"
      }
    ]
  }, 
  
  "jump-hoops": {
    files: [
      {
        expand: true, 
        cwd: 'src/jump-hoops/html/', 
        src: [
          '**/*.*'
        ], 
        dest: "dist/jump-hoops/html/"
      }
    ]
  }
}