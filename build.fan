using build

class Build : BuildPod {

	new make() {
		podName = "afJobby"
		summary = "The beginnings of a Job / Scheduler framework"
		version = Version("0.0.1")

		meta = [
			"pod.dis"		: "Jobby",
			"afIoc.module"	: "afJobby::JobbyModule",
			"repo.internal"	: "true",
			"repo.tags"		: "system",
			"repo.public"	: "true"
		]

		depends = [
			"sys          1.0.70 - 1.0",
			"concurrent   1.0.70 - 1.0",

			// ---- Core ------------------------
			"afConcurrent 1.0.20 - 1.0",
			"afIoc        3.0.6  - 3.0",
		]

		srcDirs = [`fan/`, `test/`]
		resDirs = [`doc/`]
	}
}
