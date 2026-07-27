No Material widget found.

_InkResponseStateWidget widgets require a Material widget ancestor
within the closest LookupBoundary.

In Material Design, most widgets are conceptually "printed" on a
sheet of material. In Flutter's material library, that material is
represented by the Material widget. It is the Material widget that
renders ink splashes, for instance. Because of this, many material
library widgets require that there be a Material widget in the tree
above them.

To introduce a Material widget, you can either directly include one,
or use a widget that contains Material itself, such as a Card,
Dialog, Drawer, or Scaffold.

The specific widget that could not find a Material ancestor was:
_InkResponseStateWidget