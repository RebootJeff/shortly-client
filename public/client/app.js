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
  .controller('SortCtrl', function($scope){
    $scope.predicate = 'visits';
  })
  .controller('CreateCtrl', function($scope, $http){
    $scope.submitLink = function(){
      if($scope.form.url.$valid){
        var data = JSON.stringify({url: $scope.linkToSubmit});
        $scope.showSpinner = true;
        var resetForm = function(){
          $scope.showSpinner = false;
          $scope.linkToSubmit = "";
        };
        $http.post('/links', data).success(function(){
          setTimeout(function(){
            $scope.$apply(resetForm);
          }, 300);
        });
      }
    };
  });