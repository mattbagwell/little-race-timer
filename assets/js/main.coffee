
timerApp  = angular.module('timerApp', ['ngRoute', 'LocalStorageModule', 'ngTouch', 'ngAnimate'])

timerApp.config(['$routeProvider', ($routeProvider)->
	$routeProvider
	.when('/registration', 
		templateUrl: 'templates/registration.html'
		controller: 'regCtrl'
	)
	.when('/timer',
		templateUrl: 'templates/timer.html'
		controller: 'timerCtrl'
	)
	.when('/',
		templateUrl: 'templates/home.html'
	)
	.otherwise({
		redirectTo: '/'
	})


])

timerApp.factory('Runners', (localStorageService, $http)->
	runners = {}

	runners.set = (data)->	
		runners = data
		localStorageService.set('runners', runners)
	
	runners.get = ()->
		localStorageService.get('runners')


	if(!localStorageService.get('runners')?)
		$http.get('/assets/data/dummydata.json').success((data,success)->
			runners.set(data)
		)

	runners
)

timerApp.factory('stopwatchService', ($timeout, StringFuncs, localStorageService)->
	timer =
		raceTime: null
		raceTimeout: null

	timer.start = ()->
		timer.raceTime = timer.timeFormatter()
		timer.raceTimeout = $timeout( timer.start, 100)

	timer.stop = ()->
		$timeout.cancel(timer.raceTimeout)
		timer.raceTimeout = null

	timer.restart = ()->
		timer.stop()
		timer.raceTime = null

	timer.timeFormatter = (inputTime = new Date().getTime())->
		timeDiff = (inputTime - localStorageService.get('raceStartTime')) / 1000
		h = parseInt(timeDiff / 3600)
		m = parseInt((timeDiff - h*3600) / 60)
		s = parseInt(timeDiff - h*3600 - m*60)
		times = [h,m,s].map((val, idx)->
			if timeDiff < 0 then "00" else StringFuncs.padWithZeros(val)
		)

		times.join(':')

	timer
)

timerApp.service('StringFuncs', ()->
	{
		padWithZeros: (str, digits = 2)->
			str = String(str)
			while str.length < digits
				str = "0"+str
			str
	}
)

timerApp.filter('ageGrpFilter', ()->
	(runners = null, race, gender = null, minAge = 0, maxAge = 100)->
		if runners?
			for r in runners
				results = (r for r in runners when r.age >= minAge and r.age <= maxAge and r.race is race and r.time isnt null and (r.gender is gender or gender is null))
				results.sort((a,b)->
					if a.time < b.time then 0 else 1
				)
			results
)			


navCtrl = timerApp.controller('navCtrl', ($scope, $location)->
	$scope.gotoReg = (e)->
		$location.path('/registration')

	$scope.gotoTimer = (e)->
		$location.path ('/timer')

)


timerCtrl = timerApp.controller('timerCtrl', ($scope, Runners, localStorageService, stopwatchService, ageGrpFilterFilter)->
	$scope.runners = Runners.get()

	$scope.timerIsActive = localStorageService.get('raceStartTime')?
	$scope.raceIsOver = localStorageService.get('raceEndTime')?
	$scope.bibNo = null
	$scope.stopwatch = stopwatchService

	$scope.stopwatch.start() if $scope.timerIsActive 

	$scope.startTimer = ()->
		d = new Date()
		localStorageService.set('raceStartTime', d.getTime())
		$scope.timerIsActive = true
		$scope.stopwatch.start()

	$scope.stopTimer = ()->
		if confirm ('Are you sure? This will end the race!')
			$scope.raceIsOver = true
			$scope.timerIsActive = false
			d = new Date()
			localStorageService.set('raceEndTime', d.getTime())
			$scope.stopwatch.stop()
			Runners.set($scope.runners)

	$scope.restartRace = ()->
		if confirm ('Are you sure? This will restart the race and erase everyone\'s times!')
			$scope.raceIsOver = false
			$scope.timerIsActive = false
			$scope.stopwatch.restart()
			localStorageService.remove('raceStartTime')
			localStorageService.remove('raceEndTime')
			r.time = null for r in $scope.runners
			Runners.set($scope.runners)

	$scope.recordRunnerTime = ()->
		for r, i in $scope.runners when parseInt(r.bib) is $scope.bibNo
			$scope.runners[i].time = $scope.stopwatch.timeFormatter()
		Runners.set($scope.runners)

)


regCtrl = timerApp.controller('regCtrl', ($scope, Runners)->
	$scope.runners = Runners.get()

	$scope.currentActivity = 'Add'
	$scope.saveCommand = 'Register'
	$scope.isNew = true

	$scope.$watch('isNew', ()->
		$scope.currentActivity = if $scope.isNew then 'Add' else 'Edit' 
		$scope.saveCommand = if $scope.isNew then 'Register' else 'Done'
		$scope.isEditing = !$scope.isNew
	)

	$scope.findRunner = (bib)->
		runner for runner in $scope.runners when runner.bib is bib

	$scope.createNewID = ()->
		bibs = $scope.runners.map((obj, i)->
			obj.bib
		)
		Math.max.apply(Math, bibs) + 1

	$scope.saveRunner = ()->
		if !$scope.runner.bib?
			$scope.runner.bib = $scope.createNewID()
			$scope.runner.time = null
			$scope.runners.push($scope.runner)
		$scope.runner = {race:"5K", gender:"F"}
		$scope.isNew = true
		Runners.set($scope.runners)

	$scope.loadRunner = (id)->
		$scope.runner = $scope.findRunner(id)[0]
		$scope.isNew = if $scope.runner then false else true

	$scope.deleteRunner = (id)->
		$scope.runner = $scope.findRunner(id)
		index = $scope.runners.indexOf($scope.runner)
		$scope.runners.splice(index, 1)
		Runners.set($scope.runners)
		$scope.isNew = true
)

