# Contributing

To contribute to this repository, please review the following basic guidelines, and then make a pull request.

## Versioning

Building of images for [potluck.honeyguide.net](https://potluck.honeyguide.net) happens after git update, where flavours with a higher version number than before get built.

The version must be set in the `flavour-name.ini` manifest file.

The basic structure of the versioning is as follows:

```
X.Y.Z / 0.0.1

X = Major version
Y = Minor version
Z = Build updates
```

Minor tweaks and changes increment the final digit. For example, a typo is fixed, or a config file changed to include an option. Then increment final digit to force a rebuild of the image.

```
1.1.1 --> 1.1.2
```

Many images are layered images that use a base jail. When there is a new base image, dependent pot images need to be rebuilt for it. 

The current practise of the maintainer is to increment the second last digit, and set the final digit to 1. For example:

```
1.1.3 --> 1.2.1  # new base image
```

Minor adjustments on the new base image will then increment the final digit.

## Changelog

To try and keep changes to a short format, it's preferred to list multiple changelog items under a single Major.Minor version. 

Do not include the (X.Y.Z) shown here to demonstrate an example progression. 

```
1.3

* Version bump for new base image                         (1.3.1)
* Enable milliseconds in syslog-ng for all log timestamps (1.3.2)
* Change port to 8080                                     (1.3.3)

---

1.2

* Version bump for new base image 14.1
* Extra steps to trim image size
* Fix spelling errors
* Adjust version of package

---

1.1

* Version bump for new base image

```

## Pkg steps

Avoid installing multiple packages in a single line like this:

```
step "Install packages"
pkg install -y sudo nano rsync
```

Instead break it up to individual packages like this

```
step "Install sudo"
pkg install -y sudo

step "Install nano"
pkg install -y nano

step "Install rsync"
pkg install -y rsync
```

This is easier to debug during testing or the build process. Can easily comment out problem packages.

## Checklist

Many flavours have a `CHECKLIST.md` file with specific things to check when updating that flavour. 

An upgrade of `php` or `python` can cause problems, and these should be identified in the check list file.

## Commit messages

Naming convention for commits is suggested as follows:
```
<lowercase-potluck-image-name>: <Text that starts with an uppercase letter>
```

When doing a batch of updates collectively, use a label like `hashicluster` or `honeyguide`.

