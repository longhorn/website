# Longhorn Website

[![Netlify Status](https://api.netlify.com/api/v1/badges/a7c1b4ef-e90e-477c-b9c4-f515d0dd7c7f/deploy-status)](https://app.netlify.com/sites/longhornio/deploys)

This repo houses the assets used to build the website for Longhorn, available at https://longhorn.io.

## Running the site locally

To run the website locally, you need to have the [Hugo](https://gohugo.io) static site generator installed (installation instructions [here](https://gohugo.io/getting-started/installing/)). Once Hugo is installed:

```bash
hugo server --buildDrafts --buildFuture
```

This starts Hugo in local mode. You can see access the site at http://localhost:1313.

## Publishing the site

The Longhorn site is automatically built and published by [Netlify](https://netlify.com) when changes are pushed to the `master` branch.

## New versions of the docs

To create a new version of the documentation:

1. Copy the most recent version of the documentation to create a new version. If the most recent version is 1.2.4 and you'd like to create 1.2.5:

    ```sh
    cp -rf content/docs/1.2.4 content/docs/1.2.5
    ```

1. Add the version to the `params.versions` list in [`config.toml`](./config.toml). Make sure that the list has the latest versions first.

## Contributing to docs

The documentation is split into multiple versions, with a directory for docs corresponding to each Longhorn version. For example, Longhorn 0.8.0 docs are in `content/docs/0.8.0`.

To make changes to the docs that are specific to an upcoming release, the `staging` branch is used.

The `staging` and `master` branches will both be continuously updated. To keep `staging` ready to merge into `master`, it will be rebased on `master`.

To allow docs for an upcoming release to be rebased on the most recently published docs, all changes in `staging` will be applied in the directory for the latest released version of Longhorn.

For example, changes related to Longhorn v0.8.1 will be made in the 0.8.0 until it is time to merge `staging` into `master`. Right before merging into `master`, the 0.8.0 directory would be renamed to v0.8.1 and the 0.8.0 directory would be copied from `master`.

To summarize, the process for documenting upcoming releases is as follows:

1. Make changes to the `staging` branch, in the content directory for the most recently released version of Longhorn. Don't create a new directory for the upcoming version yet.
2. If `master` changes the same files as `staging`, rebase the staging branch on master.
3. When it is time to merge `staging` into master, put the changes into a directory for the upcoming release version (`mv 0.8.0 0.8.1`), then add the latest v0.8.0 directory from `master`.