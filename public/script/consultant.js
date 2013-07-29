function ConsultantController($scope, $http) {

    $http.get("consultants/list").success(function(data) {
        $scope.consultants = data;
    });

    $scope.addConsultant = function() {
        new_consultant_as_json = JSON.stringify($scope.new_consultant);

        $http({
            method: 'POST',
            url: 'consultant',
            data: new_consultant_as_json,
            headers: {'Content-Type': 'application/JSON'}
        }).success(function(new_consultant) {
            $scope.consultants.push(new_consultant);
        });
    }
}
