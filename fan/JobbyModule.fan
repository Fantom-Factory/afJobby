using afIoc
using afConcurrent
using concurrent

const class JobbyModule {
	
	Void defineServices(RegistryBuilder defs) {
		defs.addService(JobQueue#)
	}
	
	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config["afJobby.jobQueue"]	= ActorPool() { it.name = "afJobby.jobQueue"; it.maxThreads = 1 }
		config["afJobby.jobPool"]	= ActorPool() { it.name = "afJobby.jobPool";  it.maxThreads = 1 }
	}
}
