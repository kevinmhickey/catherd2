function NewConsultantCtrl($scope, $http) {

    $http.get("list").success(function(data) {
        $scope.consultants = data;
    });

    function saveConsultants(consultants) {
        var consultants_as_JSON = JSON.stringify(consultants);
        $http({
            method: 'POST',
            url: 'save_all',
            data: "consultants=" + consultants_as_JSON,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        });
    }

    $scope.newConsultant = function() {
        $scope.consultants.push({first_name:$scope.first_name,
                                 last_name:$scope.last_name,
                                 role:$scope.role});
        saveConsultants($scope.consultants);

    }
}
