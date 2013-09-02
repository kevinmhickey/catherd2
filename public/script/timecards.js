angular.module('Timecards', []).
    config(['$routeProvider', function($routeProvider) {
        $routeProvider.
            when('/timecards', {templateUrl: 'partials/timecard_summary.html',   controller: TimecardSummaryController}).
            when('/enter_time', {templateUrl: 'partials/timecard_enter_time.html', controller: TimecardController}).
            when('/detail/:beeline_guid', {templateUrl: 'partials/timecard_detail.html', controller: TimecardDetailController}).
            when('/monthly_report/:month/:year', {templateUrl: 'partials/timecard_monthly_report.html', controller: TimecardMonthlyReportController}).
            when('/configuration', {templateUrl: 'partials/timecard_configuration.html', controller: TimecardConfigurationController}).
            when('/monthly_report', {redirectTo: '/monthly_report/07/2013'}).
            otherwise({redirectTo: '/timecards'});
    }]);

function TimecardSummaryController($scope, $http) {
    $http.get("consultants/list").success(function(consultants) {
        $scope.consultants = consultants;
    });
};

function TimecardController($scope, $http, $timeout) {
    $http.get("timecard/list_existing").success(function(existing_ending_dates) {
        $scope.existing_timecards = existing_ending_dates;
        console.log($scope.existing_timecards);

        $scope.week_ending = $scope.existing_timecards[$scope.existing_timecards.length - 1];
        $scope.getTimecardsForWeekEnding();
    });


    $scope.getTimecardsForWeekEnding = function() {
        $http.get("timecard/for_week_ending/" + $scope.week_ending).success(function(result) {
            $scope.timecards = result["timecards"];
            $scope.submitting = result["submitting"];

            if ($scope.submitting) {
                $timeout($scope.getTimecardsForWeekEnding, 2000);
            }
        });
    }

    $scope.toggleSelected = function(timecard) {
        if(!$scope.submitting) {
            if(timecard.state == "SELECTED") {
                timecard.state = timecard.original_state;
            } else {
                timecard.original_state = timecard.state;
                timecard.state = "SELECTED";
            }
        }
    }

    function prepareTimecardRequest(week_ending_date, timecards) {
        var request = {};
        request["week_ending_date"] = week_ending_date;
        request["timecards"] = {}

        timecards.forEach(function(timecard) {
            if (timecard.state == "SELECTED") {
                request["timecards"][timecard.beeline_guid] = timecard.hours_to_enter;
            }
        });

        return request;
    }

    $scope.submitTimecards = function() {
        $http({
             method: 'POST',
             url: 'timecard/submit',
             data: JSON.stringify(prepareTimecardRequest($scope.week_ending, $scope.timecards))
        })

        $timeout($scope.getTimecardsForWeekEnding, 300);
    }

    $scope.weekEndingChanged = function(week_ending) {
        $scope.week_ending = week_ending;
        if($scope.timecardExists(week_ending)) {
            $scope.getTimecardsForWeekEnding();
        }
    }

    $scope.timecardExists = function(week_ending) {
        if (week_ending != undefined && $scope.existing_timecards != undefined) {
            return $scope.existing_timecards.indexOf(week_ending) != -1;
        } else {
            return false;
        }
    }


}

function TimecardDetailController($scope, $http, $routeParams) {
    $scope.beeline_guid = $routeParams.beeline_guid;
    $scope.edit = false;

    $http.get("consultant/beeline_guid/" + $scope.beeline_guid).success(function(consultant) {
        $scope.consultant = consultant;
    });

    $http.get("../timecard/list_existing").success(function(existing_ending_dates) {
        $scope.existing_timecards = existing_ending_dates;
    });

    $http.get("rates").success(function(rates) {
       $scope.rates = rates;
    });

    $scope.saveConsultant = function() {
        $scope.edit = false;
    }

    $scope.updateTimecard = function(timecard) {
        $http({
            method: 'POST',
            url: '/timecard/time_submitted',
            params: {"week_ending" : timecard.week_ending, "beeline_guid" : $scope.beeline_guid, "hours_to_enter" : timecard.hours_submitted}
        });
    }
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
        $scope.table_headers.push("First Billable Date");
        $scope.table_headers.push("Rolloff Date")
        end_dates.forEach(function(end_date) {
            $scope.table_headers.push("Worked");
            $scope.table_headers.push("Beeline");
        });
        $scope.table_headers.push("Worked");
        $scope.table_headers.push("Beeline");
        $scope.table_headers.push("");
//        $scope.table_headers.push("Discounted");
    };

    function buildTableLines(consultants, end_dates) {
        $scope.table_lines = [];
        consultants.forEach(function(consultant) {
            consultant.hours_submitted_month = 0;
            consultant.hours_worked_month = 0;
            var line = [];
            line.push(consultant.last_name + ", " + consultant.first_name);
            line.push(consultant.first_billable_date);
            line.push(consultant.rolloff_date);
            end_dates.forEach(function(end_date) {
                consultant.timecards.forEach(function(timecard) {
                    if (timecard.week_ending == end_date) {
                        line.push(timecard.hours_worked);
                        line.push(timecard.hours_submitted);
                        consultant.hours_submitted_month += timecard.hours_submitted;
                        consultant.hours_worked_month += timecard.hours_worked;
                    }
                })
            });
            line.push(consultant.hours_worked_month);
            line.push(consultant.hours_submitted_month);
            consultant.total_fees = consultant.hours_submitted_month * $scope.rates[consultant.grade];
            line.push($filter('currency')(consultant.total_fees, "$"));
            consultant.total_fees_discount = consultant.total_fees * .91;

            if((consultant.hours_worked_month > 0) || (consultant.hours_submitted_month > 0)) {
                $scope.table_lines.push(line);
            }
        });

        $scope.table_lines.sort();
    }

}

function TimecardConfigurationController($scope, $http) {
    $http.get("configuration").success(function(configuration) {
        $scope.configuration = configuration;
    });

    $scope.saveConfiguration = function() {
        $http({
            method: 'POST',
            url: 'configuration',
            data: JSON.stringify($scope.configuration),
            headers: {'Content-Type': 'application/JSON'}
        }).success(function(configuration) {
            $scope.configuration = configuration;
        });
    }
}