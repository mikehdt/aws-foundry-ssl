# Upgrading from a previous version

Minor updates should be installable in-place via the Foundry admin screen. **Major Foundry updates need some planning**.

First, log in to the Foundry admin interface. From the Foundry version update screen, there's an option to test your add-ons for compatibility after checking versions, so you can find out what will work and what won't. Many add-ons usually need to be updated, so it's good to know what might work and what won't.

Then, make sure to back up all the Foundry data from your existing EC2 instance. The easiest way to do this is via SCP, using the SSH keypair created for the EC2.

Once you've downloaded all your foundry worlds and user data, make a note of all the add-ons you use as you'll likely need to reinstall them manually. Many add-ons change repositories, dependencies, or simply aren't compatible and may no longer be maintained. Once you're sure you've got everything, manually stop the EC2 server.

Then, deploy a new CloudFormation stack with the new version of Foundry.

Once the new stack is deployed, you'll need to:

- SSH into the server and set the permissions so you can upload via SCP with `sudo chmod -R 775 /foundrydata/Data`
- Then, re-upload your world data to this folder via SCP
- Once complete, run `sudo /aws-foundry-ssl/utils/fix_folder_permissions.sh`
- Restart the Foundry server with `sudo /aws-foundry-ssl/utils/restart_foundry.sh`
- Open up your browser and navigate to your new Foundry address
- Enter your license key into Foundry, set your admin password, and then _manually_ reinstall your plugins
- Start your new world, and let it migrate if needed

At any point if something goes awry, you can always stop the new EC2 and start the old EC2 to test.

Once up and running, Foundry should prompt you to upgrade the save format if it's changed in any way. Note that this is an irreversible process, so keep a back-up of the old version at least for a little while!

When you're happy that the new server and Foundry version is working as you wish, you can tear down the _old_ CloudFormation stack. Make sure to update the scheduler if you're using it.

_Note: You can do a major version upgrade in-place on your current server, but that's at your own initiative as it can be risky._
