To run k8s via mac, start by building conjur. It will create an image but won't push 
it to any repository:

    ./build.sh

Then run:

    cd ci/authn-k8s && summon ./test.sh gke
    
    # or run the following to stop any docker container before
    ci/authn-k8s/localrun/stop_start.sh 

The execution will stop be blocked, just before running conjur, with message:
   
    'while ! curl --silent --head --fail localhost:80 > /dev/null; do sleep 1; done'

This give opportunity to modify conjur code, adding `binding.pry` for example, just
before running conjur. 

What it also done is to copy `git diff` files into deployed master. This saves
precious time of building all over again images on each change we make in conjur
code.


Open another terminal and run conjur master:
      
     cd ci/authn-k8s/localrun && ./in.sh launch_conjur_master.sh

Once `build.sh` script outputs the line ` sleep 9999999`, we can execute tests
inside cucumber container. One way to do it is:
     
     ./in.sh run_tests.sh
     
