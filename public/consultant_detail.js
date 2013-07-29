function ConsultantDetailController($scope, $http, $location) {
    $scope.beeline_guid = $location.search().beeline_guid;

    $http.get("beeline_guid/" + $scope.beeline_guid).success(function(consultant) {
        $scope.consultant = consultant;
        console.log($scope.consultants);
    });

    $http.get("../timecard/list_existing").success(function(existing_ending_dates) {
        $scope.existing_timecards = existing_ending_dates;
        console.log($scope.existing_timecards);
    });

}