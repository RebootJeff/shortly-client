angular.module('shortly', [])
  .config(['$routeProvider', function($routeProvider){
    $routeProvider.when('/', {
      controller: 'IndexCtrl',
      templateUrl: '/client/templates/index.html'
    })
    .when('/create', {
      controller: 'CreateCtrl',
      templateUrl: '/client/templates/create.html'
    })
    .otherwise({
      redirectTo: '/'
    });
  }])
  .controller('IndexCtrl', function($scope, $http){
    $http({
      method: 'GET',
      url: '/links'
    })
      .success(function(data, status){
        console.log(data);
        $scope.links = data;
      })
      .error(function(data, status){
        console.log('IndexCtrl Error! Data:', data);
      });
  })
  .controller('CreateCtrl', function($scope, $http){
    $scope.submitLink = function(){
      var data = JSON.stringify({url: $scope.linkToSubmit});
      $http.post('/links', data);
    };
  });