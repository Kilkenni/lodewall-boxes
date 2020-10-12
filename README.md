# lodewall_boxes
A small framework mod for Stonehearth aimed at creating animated containers.

It's more of a proof of concept and study at how to integrate animated models into Stonehearth using exclusively free and open-source tools.

##Credits

This mod would not be possible without gracious help from Drotten, Hyrule_Symbol and all of the Stonehearth community. Thank you folks!

##How to apply it if you don't want to animate:

Look at how the example iron chest is done. You can build upon this mod reusing the animation files. It's not necessary to edit this mod itself. Just refer to the required files listed in the manifest.
To make the existing animation work your chest should have a certain file structure:

- Animation is based on the assumption the model is 20x20x20 with zero being at the centre of this bounding box.
- Chest hinges should be at coordinates Y:10, Z:10 (i.e. at the border of the bounding box - I'm using MagicaVoxel coordinates). If positioning makes your chest float in the air, you can fix it by setting the appropriate model origin in your model's json.
- Your chest should have exactly two matrices (layers). The one should be called "chest", the other "lid". Obviously the lid should be the part that you want to be rotating.

##How it works

Idea behind it is rather simple: I've taken the activator triggering animation on living entity approaching the **door** in vanilla Stonehearth and applied it to a **container** entity (so that a container animates when someone approaches it).

Step-by-step instruction on how to process a premade model to make it animated using this mod can be found below. Intermediate files (as well as sample animation GIFs) can be found in "_SOURCE". Note that this guide was relevant as of 2016 and  **probably is outdated now**, so it is posted here **for reference only**.
You will need:
- MagicaVoxel
- VoxelShop (required only to slice a model into layers since Magica can't do it)
- Blender

1. Create a solid model in Magica. Save it as qb.
2. Save model parts for animation into obj from Magica (this is important!). For the chest we'll need the base and the lid.
3. Load qb from Magica into VoxelShop. Separate into layers (matrices). Save it again.
Important: do **NOT** export from VoxelShop for animation.
4. Load obj files into Blender. Set origins. Export skeleton.
5. Note that every model part you’ve just loaded is rotated 90 degrees around X axis. Rotate it back to 0. Yup, your model is a mess now. That's how it should be.
6. Animate as usual and export animations.
Note that the skeleton can be exported at any time after setting origins since rotations are not saved. Animation, however, must be made and saved **after** model parts have been rotated to 0 degrees.

Reasoning behind these steps:
Rotation trick takes root in Z-up right-hand basis in Blender. Both Qubicle and SH (I assume) use Y-up right-hand basis.
As for NOT being able to import to Blender from VoxelShop… Bad news. According to the graphics inside the program VoxelShop uses left-hand basis system. While we can get Y-up from Z-up with a simple rotation 90 degrees, getting a right-hand basis from a left-hand basis is not that easy. So my conclusion is VoxelShop currently should not be used in anything aside from light model edits (and especially not in animation) if you want to combine it with Magica and/or Blender.

For anyone who reached this point in the readme: guess you're really stubborn. If you're curious about the discussion behind it, it can be found here: (https://discourse.stonehearth.net/t/need-help-with-modelling/21672/59).