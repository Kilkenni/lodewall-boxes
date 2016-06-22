# lodewall-boxes
A small framework mod for Stonehearth aimed at creating animated containers.

##Credits

This mod would not be possible without gracious help from Drotten, Hyrule_Symbol and all of the Stonehearth community. Thank you folks!

##How it works:

Look at how the example iron chest is done. You can build upon this mod reusing the animation files. It's not necessary to edit this mod itself. Just refer to the required files listed in the manifest.
To make the existing animation work your chest should have a certain file structure:

- Animation is based on the assumption the model is 20x20x20 with zero being at the centre of this bounding box.
- Chest hinges should be at coordinates Y:10, Z:10 (i.e. at the border of the bounding box - I'm using MagicaVoxel coordinates). If positioning makes your chest float in the air, you can fix it by setting the appropriate model origin in your model's json.
- Your chest should have exactly two matrices (layers). The one should be called "chest", the other "lid". Obviously the lid should be the part that you want to be rotating.