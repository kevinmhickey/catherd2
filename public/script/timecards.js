angular.module('Timecards', []).
    config(['$routeProvider', function($routeProvider) {
        $routeProvider.
            when('/timecards', {templateUrl: 'partials/timecard_summary.html',   controller: TimecardSummaryController}).
            when('/enter_time', {templateUrl: 'partials/timecard_enter_time.html', controller: TimecardController}).
            when('/detail/:beeline_guid', {templateUrl: 'partials/timecard_detail.html', controller: TimecardDetailController}).
            otherwise({redirectTo: '/timecards'});
    }]);

function TimecardSummaryController($scope, $http) {
    $http.get("consultants/list").success(function(consultants) {
        $scope.consultants = consultants;
    });
};

function TimecardController($scope, $http) {
    $http.get("consultants/list").success(function(consultants) {
        $scope.consultants = consultants;
        $scope.consultants.forEach(function(consultant) {
            consultant.timecards.forEach(function(timecard) {
                timecard.hours_to_enter = timecard.hours_submitted > 0 ? 0 : timecard.hours_worked;
            });
        });
        console.log($scope.consultants);

        $scope.week_ending = "2013-07-07";
    });

    $http.get("timecard/list_existing").success(function(existing_ending_dates) {
        $scope.existing_timecards = existing_ending_dates;
        console.log($scope.existing_timecards);
    });


    $scope.addTimecard = function(week_ending) {
        console.log("Adding timecard for week ending " + week_ending);
        $http({
            method: 'POST',
            url: 'timecard/add',
            params: {"week_ending_date" : week_ending}
        }).success(function(consultants) {
                $scope.consultants = consultants;
                $scope.consultants.forEach(function(consultant) {
                    consultant.timecards.forEach(function(timecard) {
                        timecard.hours_to_enter = timecard.hours_submitted > 0 ? 0 : timecard.hours_worked;
                    });
                });

                $scope.existing_timecards.push(week_ending);
                console.log($scope.existing_timecards);
            });
    }

    $scope.timecardExists = function(week_ending) {
        if (week_ending != undefined && $scope.existing_timecards != undefined) {
            return $scope.existing_timecards.indexOf(week_ending) != -1;
        } else {
            return false;
        }
    }

    $scope.toggleEnterAll = function() {
        $scope.consultants.forEach(function(consultant) {
            consultant.enter_time = $scope.enter_all;
        });
    }

    function consultantTimecard(consultant, week_ending) {
        found_timecard = undefined;
        consultant.timecards.forEach(function(timecard) {
            console.log(timecard);
            console.log(week_ending);
           if (timecard.week_ending == week_ending) {
               console.log("Match!");
               found_timecard = timecard;
           }
        });

        return found_timecard;
    }

    enterTime = function(guid, week_ending, hours_to_enter) {
        $http({
            method: 'POST',
            url: 'timecard/enter_time',
            params: {"week_ending": week_ending, "hours_to_enter" : hours_to_enter, "beeline_guid": guid}
        }).success(function(consultants) {
                $scope.consultants = consultants;
                $scope.consultants.forEach(function(consultant) {
                    consultant.timecards.forEach(function(timecard) {
                        timecard.hours_to_enter = timecard.hours_submitted > 0 ? 0 : timecard.hours_worked;
                    });
                });

                $scope.existing_timecards.push(week_ending);
                console.log($scope.existing_timecards);
            });
    }

    $scope.enterSelectedTimes = function() {
        $scope.consultants.forEach(function(consultant) {
            if (consultant.enter_time) {
                var timecard = consultantTimecard(consultant, $scope.week_ending);
                enterTime(consultant.beeline_guid, $scope.week_ending, timecard.hours_to_enter);
            }
        });
    }
}

function TimecardDetailController($scope, $http, $routeParams) {
    $scope.beeline_guid = $routeParams.beeline_guid;

    $http.get("consultant/beeline_guid/" + $scope.beeline_guid).success(function(consultant) {
        $scope.consultant = consultant;
    });

    $http.get("../timecard/list_existing").success(function(existing_ending_dates) {
        $scope.existing_timecards = existing_ending_dates;
    });

    $http.get("rates").success(function(rates) {
       $scope.rates = rates;
    });

}