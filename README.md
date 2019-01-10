# VDT (Virtual Deployment Toolkit)

This project was birthed out of necessity, while its initial contributors sought a solution to streamline the provisioning of a training platform. [PowerShell](https://github.com/PowerShell/PowerShell), [PowerCLI]( https://www.powershellgallery.com/packages/VMware.PowerCLI/10.1.1.8827524) and [DSC (Desired State Configuration)](https://docs.microsoft.com/en-us/powershell/dsc/overview/overview) surfaced as got to technologies considering all things. Like many things in life the initial contributors grew to feel at home while working on this project and therefore wanted to bring it to GITHUB to allow continuous development and better source control. We look forward to feedback and contribution from the community. Though the tool was created to solve a niche case, we believe with input from a much larger community together we can alleviate pain and sufferance as it pertains to infrastructure and systems provisioning.

## Tool Dependencies

This is tool is a work in progress.
1. Any OS able to run [PowerShell](https://github.com/PowerShell/PowerShell) and [PowerCLI]( https://www.powershellgallery.com/packages/VMware.PowerCLI/10.1.1.8827524) libraries.
2. [vSphere](https://www.vmware.com/products/vsphere.html) and [vCenter Server Appliance](https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.vcsa.doc/GUID-223C2821-BD98-4C7A-936B-7DBE96291BA4.html)

## Current Deployment Pipeline 

The tool leverages [vmware vApps](https://pubs.vmware.com/vca/index.jsp?topic=%2Fcom.vmware.vca.od.ug.doc%2FGUID-3F4BF45F-89CE-4478-B6D5-5BD7EE749C08.html) as master containers for training environments. I like to think of it as a poor-man’s [Virtual desktop infrastructure (VDI)](https://searchvirtualdesktop.techtarget.com/definition/virtual-desktop-infrastructure-VDI) of sorts. This approach adopts the build once, deploy many philosophy.

## How to Engage, Contribute and Provide Feedback
Some of the best ways to contribute are to try things out, file bugs, pull request and join in design conversations.
