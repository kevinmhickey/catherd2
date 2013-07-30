angular.module('Timecards', []).
    config(['$routeProvider', function($routeProvider) {
        $routeProvider.
            when('/timecards', {templateUrl: 'partials/timecard_summary.html',   controller: TimecardSummaryController}).
            when('/enter_time', {templateUrl: 'partials/timecard_enter_time.html', controller: TimecardController}).
            when('/detail/:beeline_guid', {templateUrl: 'partials/timecard_detail.html', controller: TimecardDetailController}).
            when('/monthly_report/:month/:year', {templateUrl: 'partials/timecard_monthly_report.html', controller: TimecardMonthlyReportController}).
            when('/monthly_report', {redirectTo: '/monthly_report/07/2013'}).
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

function TimecardMonthlyReportController($scope, $http, $routeParams, $filter) {
    console.log($routeParams);
    $scope.report_month = parseInt($routeParams.month);
    $scope.report_year = parseInt($routeParams.year);

    $http.get("consultants/list").success(function(consultants) {
        $scope.consultants = consultants;
        $http.get("rates").success(function(rates) {
            $scope.rates = rates;
            $http.get("timecard/list_existing").success(function(existing_ending_dates) {
                $scope.existing_end_dates = existing_ending_dates;
                $scope.end_dates_in_month = endDatesInMonth(existing_ending_dates, $scope.report_month, $scope.report_year);

                buildReportTable(consultants, rates, $scope.end_dates_in_month);
                calculateTotals(consultants);
            });
        });
    });

    function calculateTotals(consultants) {
        $scope.total_fees = 0;
        $scope.total_fees_discounted = 0;

        consultants.forEach(function(consultant) {
           $scope.total_fees += consultant.total_fees;
           $scope.total_fees_discounted += consultant.total_fees_discount;
        });

        $scope.expenses = $scope.total_fees * 0.12;
    }

    function endDatesInMonth(existing_end_dates, month_string, year_string) {
        var month = parseInt(month_string);
        var year = parseInt(year_string);
        var end_dates_in_month = existing_end_dates.filter(function(end_date) {
            var date = new Date(end_date);
            return (((date.getMonth() + 1) == month) && (date.getFullYear() == year))
        });

        return end_dates_in_month;
    }

    function buildReportTable(consultants, rates, end_dates_in_month) {
        buildTableHeaders(end_dates_in_month);
        buildTableLines(consultants, end_dates_in_month);
    };

    function buildTableHeaders(end_dates) {
        $scope.table_headers = [];
        $scope.table_headers.push("Name");
        end_dates.forEach(function(end_date) {
            $scope.table_headers.push("Hours Worked " + end_date);
            $scope.table_headers.push("Hours Submitted " + end_date);
        });
        $scope.table_headers.push("Total Hours Submitted");
        $scope.table_headers.push("Fees");
        $scope.table_headers.push("Fees With Discount");
    };

    function buildTableLines(consultants, end_dates) {
        $scope.table_lines = [];
        consultants.forEach(function(consultant) {
            consultant.hours_submitted_month = 0;
            var line = [];
            line.push(consultant.first_name + " " + consultant.last_name);
            end_dates.forEach(function(end_date) {
                consultant.timecards.forEach(function(timecard) {
                    if (timecard.week_ending == end_date) {
                        line.push(timecard.hours_worked);
                        line.push(timecard.hours_submitted);
                        consultant.hours_submitted_month += timecard.hours_submitted;
                    }
                })
            });
            line.push(consultant.hours_submitted_month);
            consultant.total_fees = consultant.hours_submitted_month * $scope.rates[consultant.grade];
            line.push($filter('currency')(consultant.total_fees, "$"));
            consultant.total_fees_discount = consultant.total_fees * .91;
            line.push($filter('currency')(consultant.total_fees_discount, "$"));
            $scope.table_lines.push(line);

        });
    }

}