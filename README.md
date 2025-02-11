[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com)

## Solution Overview

The **Maica Sync Trigger for Products <> Support Items** automates the bi-directional synchronisation of **Maica Support Item, Price List, and Price List Entry** records with **Salesforce Product, Price Book, and Price Book Entry** records.

This ensures seamless data consistency and the creation of **Maica Service Agreements** and **Agreement Items** from converted **Opportunities** and **Opportunity Line Items**.

## Feature Highlights

- **Automated Synchronisation** – Triggers fire on **INSERT**, **UPDATE**, and **DELETE** events to keep Maica and Salesforce standard objects in sync.
- **Custom Field Synchronisation** – Any new custom fields and picklists created in Maica Support Item related objects and Salesforce Product related objects must be replicated in the corresponding objects to ensure sync is automated.
- **Dedicated Settings** - A dedicated Settings called “Organisation Settings” with a “Product Sync Management” Tab for configuring and managing the sync processes.

## Using the Product Sync Management Tab

The **Product Sync Management** tab in **Organisation Settings** tab allows you to control and configure the synchronisation between **Maica Support Items, Price Lists, and Price List Entries** and their corresponding **Salesforce Standard objects**: Products, Price Books, and Price Book Entries. Follow the instructions below to set up and manage your sync process.

1. **Accessing the Product Sync Management Tab**
   - Navigate to App Launcher in Salesforce
   - Search for Organisational Settings and click on it
   - You will then see the Product Sync Management Tab


2. **Configuring Sync Settings**
   - **Sync Direction** determines which set of records will be the “master” for synchronization.
     - **Standard to Maica** → Syncs and creates Maica Support Items, Price Lists, and Price List Entries.
     - **Maica to Standard** → Syncs and creates Products, Price Books, and Price Book Entries.
     
    *Tip*: Choose the direction based on where your primary data source resides.


3. **Select Sync Mode** 
   - The **Mode** defines when and how the sync process runs.
       - **Triggered** → Runs automatically when records are created, updated, or deleted.
       - **Scheduled** → Runs once daily at a specified time.
       - **On Demand** → Manually triggered when needed using the Sync Now button.

    *Tip*: If you require **real-time updates**, use **Triggered Mode**. If you want manual control, use **On Demand**. Important: If the sync direction is Standard to Maica and mode is Triggered, Price List Entries must be synced manually due to Salesforce limitations.