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

    $scope.enterTime = function(guid, week_ending, hours_to_enter) {
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

    $scope.timecardExists = function(week_ending) {
        if (week_ending != undefined && $scope.existing_timecards != undefined) {
            return $scope.existing_timecards.indexOf(week_ending) != -1;
        } else {
            return false;
        }
    }


//-------------------------------------------------------------------------------------------------------

    $scope.has_timecard_for = function(consultant, week_ending) {
        var found = false;
        consultant.timecards.forEach(function(timecard) {
           if (timecard.week_ending == week_ending && timecard.hours_needed > 0) {
               found = true;
           }
        });
        return found;
    }

    function hoursNeeded(week_ending, rolloff) {
        var week_ending_date = new Date(week_ending);
        var week_start_date = new Date(week_ending_date);
        week_start_date.setDate(week_start_date.getDate() - 7);
        var rolloff_date = new Date(rolloff);

        console.log("Week Start: " + week_start_date + " Week End: " + week_ending_date + " Rolloff: " + rolloff_date);
        console.log("Week Start: " + week_start_date.toString() + " Week End: " + week_ending + " Rolloff: " + rolloff);

            if (rolloff_date < week_start_date) {
                console.log("After")
                console.log("0 hours");
                return 0;
            } else if (rolloff_date > week_ending_date) {
                console.log("Before")
                console.log("40 hours");
                return 40;
            } else {
                console.log("Between");
                console.log(8 * rolloff_date.getDay() + " hours");
                return 8 * (rolloff_date.getDay() + 1);
            }

    }

    function saveConsultants(consultants) {
        var consultants_as_JSON = JSON.stringify(consultants);
        console.log("Saving: " + consultants_as_JSON);
        $http({
            method: 'POST',
            url: 'consultants/save_all',
            data: consultants_as_JSON,
            headers: {'Content-Type': 'application/JSON'}
        });
    }




//    $scope.enterTime = function(guid, week_ending, hours_needed) {
//        console.log("Entering " + hours_needed + " for " + guid + " " + week_ending);
//        enter_time = {};
//        enter_time["week_ending"] = week_ending;
//        enter_time["timecards"] = [];
//
//        timecard = {};
//        timecard["guid"] = guid;
//        timecard["hours"] = hours_needed;
//
//        enter_time.timecards.push(timecard);
//        var enter_time_JSON = JSON.stringify(enter_time);
//        console.log(enter_time_JSON);
//
//        $http({
//            method: 'POST',
//            url: 'timecard/enter_time',
//            data: enter_time_JSON,
//            headers: {'Content-Type': 'application/JSON'}
//        }).success(function(result) {
//            console.log(result);
//            $scope.consultants.forEach(function(consultant) {
//                console.log(consultant.beeline_guid + " " + guid);
//                if(consultant.beeline_guid == guid) {
//                    console.log("Found consultant");
//                    consultant.timecards.forEach(function(timecard) {
//                        if (timecard.week_ending == week_ending) {
//                            console.log("Found timecard");
//                            timecard.hours_submitted = result.timecards[0].hours_submitted;
//                        }
//                    })
//
//                    var hours_needed = 0;
//                    consultant.timecards.forEach(function(timecard) {
//                        hours_needed += timecard.hours_needed - timecard.hours_submitted;
//                    });
//                    consultant.hours_needed = hours_needed;
//                }
//            });
//
//            saveConsultants($scope.consultants);
//        });
//    }



}