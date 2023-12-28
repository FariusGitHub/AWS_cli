https://github.com/FariusGitHub/AWS_cli

Please refer to 
https://medium.com/p/9b12eac5622a/edit
for more detailed story about this code.

When the 3nodes_with_cli.sh was downloaded into your machine,
use Visual Code or similar by running with ./3nodes_with_cli.sh

As the execution above running successfully with no error,
you will normally see a new VPC, subnet, internet gateway,
route table, security group and EC2 are popping up.

I am using my existing pem key for this project, you can use yours.

Open ssh terminal from the given url for each node to check the ping.

You may use commented section at the bottom of the code to delete them.
(sorry it's not terraform, we need to wipe out all of them manually).
For EC2 deletion, I would prefer to delete the three manually. 

