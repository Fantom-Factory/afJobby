using afIoc
using afConcurrent
using concurrent

** The beginnings of a Job / Scheduler framework.
const class JobQueue {
	private const AtomicRef			onJobErrRef	:= AtomicRef(null)

	** Custom handler for Errs thrown by jobs.
	** May be set at anytime. Must be immutable. 
	|Err|? onJobErr {
		get { onJobErrRef.val }
		set { onJobErrRef.val = it }
	}
	
	@Inject
	private const Log				log

	@Inject
	private const Scope 			scope

	@Inject { id="afJobby.jobQueue"; type=Job[]# }
	private const SynchronizedList	jobQueue

	** Each job runs in it's own Actor, that's how we handle jobs over running into the next execution time
	@Inject { id="afJobby.jobPool"; type=Job:Synchronized# }
	private const SynchronizedMap	jobPool

	private const ActorPool			jobThreadPool		:= ActorPool() { it.name = "afJobby.jobThreadPool" }
	private const AtomicRef			jobSchedThreadRef	:= AtomicRef(newJobThread())

	private Synchronized jobSchedThread {
		get { jobSchedThreadRef.val }
		set { jobSchedThreadRef.val = it }
	}
	
	private new make(|This| f) { f(this) }
	
	Job createJob(Type jobType) {
		job := Job {
			it.jobType	= jobType
			it.job = |job| { scope.build(jobType) -> runJob(job) } 
		}
		return job
	}
	
	Void runJob(Job job, Bool reschedule) {		
		jobThread := null as Synchronized
		
		if (reschedule)
			jobThread = jobPool.getOrAdd(job) { Synchronized(jobThreadPool) }
		else
			jobThread = Synchronized(jobThreadPool)
		
		jobThread.async |->| {
			job.lastRunTime = job.nextRunTime
			job.nextRunTime = null
			
			if (!job.isCancelled) {
				scope.registry.activeScope.createChild("job") {
					try {
						job.job(job)	// job jobbed!
						
					} catch (Err jobErr)	{
						(onJobErr ?: |Err err| {
							log.err("Error thrown by Job ${job.jobType.qname}", err)
						}).call(jobErr)
					} 					
				}
			}
			
			if (reschedule)
				scheduleJob(job)
		}
	}

	Void scheduleJob(Job job) {
		if (!job.isCancelled) {
			job.calcNextRunTime
			jobQueue.add(job)
			rescheduleQueue
			log.info("Scheduled ${job.typeof.name.toDisplayName} to run at " + job.nextRunTime.toLocale("DD MMM YYYY, hh:mm:ss") + ", and every ${DurationLocale.approx(job.interval)} thereafter")

		} else {
			jobPool.remove(job)
			log.info("Cancelled ${job.typeof.name.toDisplayName}")
		}		
	}

	private Void rescheduleQueue() {
		jobQueue.lock.async |->| {
			if (jobQueue.isEmpty)
				return
	
			jobSchedThread.actor.pool.stop.join
			jobSchedThread = newJobThread
			
			jobQueue.val = jobQueue.val.rw.sort |Job j1, Job j2->Int| { j1.nextRunTime <=> j2.nextRunTime }
			job		:= (Job) jobQueue.removeAt(0)
			runIn	:= job.nextRunTime - DateTime.now
			jobSchedThread.asyncLater(runIn) |->| { runJob(job, true) }	
		}
	}
	
	private Synchronized newJobThread() {
		Synchronized(ActorPool() { it.name = "afJobby.jobThread" })
	}
}
