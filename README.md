debugDescription
================

The purpose of this is to demo the automation of building `-debugDescription` strings for model objects. This is done by querying for the model object's properties at runtime and then using parsing the encoded type signatures to get and display formatted data.


Using
=====

Add the files `BaseDataModelObject.h` and `BaseDataModelObject.m` to your project. You will get an error when attempting to build without enabling the flag `-fno-objc-arc` flag on `BaseDataModelObject.m` file.


Notes
=====

* struct properties: This code will attempt to display struct contents, however due to behavior in the Objective-C runtime if a struct is packed or not is not recorded at compile-time. This means that the size of a struct cannot be determined at runtime based on the encoded type signature alone. The exception to this is when the size of the struct would be the same when it is packed or not. This varies based on architecture alignment rules. What this means for you: struct properties will be unpacked and have member values displayed if the packed and non-packed sizes match, otherwise the contents of the struct will be displayed via NSValue representation.

* `BOOL` vs `char`: Since the type `BOOL` is a `signed char`, it will be encoded as such in the runtime.  This code will look at the property name and if it starts with "is" or "has" will assume it is a `BOOL` rather than a `signed char`.

