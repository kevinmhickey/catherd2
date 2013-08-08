function ConsultantController($scope, $http) {

    $http.get("consultants/list").success(function(data) {
        $scope.consultants = data;
    });

    $http.get("projects").success(function(data) {
        $scope.projects = [];
        for (var project in data) {
            $scope.projects.push(project);
        }
    });

    $http.get("rates").success(function(data) {
        $scope.grades = [];
        for (var grade in data) {
            $scope.grades.push(grade);
        }
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
