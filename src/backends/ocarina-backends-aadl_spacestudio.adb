with Ocarina.Instances;
with Ocarina.Backends.Expander;
with Ocarina.Backends.Messages;
with Ocarina.Backends.AADL_SpaceStudio.Main;
with Ocarina.Backends.Utils;
with Ocarina.Backends.python.Nodes;
with Ocarina.Backends.python.Nutils;
with Ocarina.Backends.python.Generator;
with GNAT.Command_Line; use GNAT.Command_Line;

with Ocarina.Namet; use Ocarina.Namet;

package body Ocarina.Backends.AADL_SpaceStudio is

   use Ocarina.Instances;
   use Ocarina.Backends.Messages;
   use Ocarina.Backends.Utils;
   use Ocarina.Backends.Expander;

   package PTN renames Ocarina.Backends.python.Nodes;
   package PTU renames Ocarina.Backends.python.Nutils;

   Generated_Sources_Directory : Name_Id := No_Name;

   procedure Visit_Architecture_Instance (E : Node_Id);
   --  Most top level visitor routine. E is the root of the AADL
   --  instance tree. The procedure does a traversal for each
   --  compilation unit to be generated.

   --------------
   -- Generate --
   --------------

   procedure Generate (AADL_Root : Node_Id) is
      Instance_Root : Node_Id;

   begin
      Instance_Root := Instantiate_Model (AADL_Root);

      if No (Instance_Root) then
         Display_Error ("Cannot instantiate the AADL model", Fatal => True);
      end if;

      --  Expand the AADL instance

      Expand (Instance_Root);

      Visit_Architecture_Instance (Instance_Root);

      --  Abort if the construction of the python tree failed

      if No (Python_Root) then
         Display_Error ("python generation failed", Fatal => True);
      end if;

      Enter_Directory (Generated_Sources_Directory);
      --  Create the Python file

      python.Generator.Generate (Python_Root);

      Leave_Directory;
   end Generate;

   ----------
   -- Init --
   ----------

   procedure Init is
   begin
      Generated_Sources_Directory := Get_String_Name (".");
      Initialize_Option_Scan;
      loop
         case Getopt ("* o:") is
            when ASCII.NUL =>
               exit;

            when 'o' =>
               declare
                  D : constant String := Parameter;
               begin
                  if D'Length /= 0 then
                     Generated_Sources_Directory := Get_String_Name (D);
                  end if;
               end;

            when others =>
               null;
         end case;
      end loop;

      Register_Backend ("spacestudio", Generate'Access, SpaceStudio);
   end Init;

   -----------
   -- Reset --
   -----------

   procedure Reset is
   begin
      null;
   end Reset;

   ---------------------------------
   -- Visit_Architecture_Instance --
   ---------------------------------

   procedure Visit_Architecture_Instance (E : Node_Id) is
   begin
      Python_Root := PTU.New_Node (PTN.K_HI_Distributed_Application);
      PTN.Set_Name (Python_Root, No_Name);
      PTN.Set_Units (Python_Root, PTU.New_List (PTN.K_List_Id));
      PTN.Set_HI_Nodes (Python_Root, PTU.New_List (PTN.K_List_Id));

      PTU.Push_Entity (Python_Root);

      AADL_SpaceStudio.Main.Visit
        (E,
         Get_String_Name ("willdesepear"),
         Get_String_Name ("Hardware"));

      PTU.Pop_Entity;
   end Visit_Architecture_Instance;

end Ocarina.Backends.AADL_SpaceStudio;
