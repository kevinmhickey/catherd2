function BeelineController($scope, $http) {
    $http.get("consultants/list").success(function(consultants) {
        $scope.consultants = consultants;
        $scope.timecards = []
        for (var i = 0; i < consultants.length; i++) {
            var timecard = {};
            timecard["guid"] = consultants[i].beeline_guid;
            timecard["hours_needed"] = consultants[i].hours_needed;
            timecard["name"] = consultants[i].last_name;
            $scope.timecards.push(timecard);
        }
        console.log($scope.consultants);
    });

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


    $scope.addTimecard = function(week_ending) {


        console.log("Adding timecard for week ending " + week_ending);

        $scope.consultants.forEach(function(consultant) {
            var timecard = {};
            timecard.week_ending = week_ending;
            timecard.hours_submitted = 0;
            timecard.hours_needed = hoursNeeded(week_ending, consultant.rolloff);
            timecard.hours_to_enter = timecard.hours_needed;
            console.log(consultant.last_name + ": " + timecard.hours_needed);
            consultant.timecards.push(timecard);
            consultant.hours_needed += timecard.hours_needed;
        });

        console.log($scope.consultants);
    }



    $scope.enterTime = function(guid, week_ending, hours_needed) {
        console.log("Entering " + hours_needed + " for " + guid + " " + week_ending);
        enter_time = {};
        enter_time["week_ending"] = week_ending;
        enter_time["timecards"] = [];

        timecard = {};
        timecard["guid"] = guid;
        timecard["hours"] = hours_needed;

        enter_time.timecards.push(timecard);
        var enter_time_JSON = JSON.stringify(enter_time);
        console.log(enter_time_JSON);

        $http({
            method: 'POST',
            url: 'timecard/enter_time',
            data: enter_time_JSON,
            headers: {'Content-Type': 'application/JSON'}
        }).success(function(result) {
            console.log(result);
            $scope.consultants.forEach(function(consultant) {
                console.log(consultant.beeline_guid + " " + guid);
                if(consultant.beeline_guid == guid) {
                    console.log("Found consultant");
                    consultant.timecards.forEach(function(timecard) {
                        if (timecard.week_ending == week_ending) {
                            console.log("Found timecard");
                            timecard.hours_submitted = result.timecards[0].hours_submitted;
                        }
                    })

                    var hours_needed = 0;
                    consultant.timecards.forEach(function(timecard) {
                        hours_needed += timecard.hours_needed - timecard.hours_submitted;
                    });
                    consultant.hours_needed = hours_needed;
                }
            });
        });
    }



}