1/18/2023 - Store parent and color explicitly while in debugging mode
* Simplify parent and color storage so it's easy to see values in a debugger

1/14/2024 - Update to store the color attribute as the LSB in the parent pointer.
* Moved from storing the color attribute explicitly in the data structure to encoding it in the pointer to a nodes parent.
* Added some convenience functions for traversing encoded parent pointers.

