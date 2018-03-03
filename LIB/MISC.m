classdef MISC
 
 methods(Static = true)
  
  function dockStyle()
   set(0, 'ShowHiddenHandles', 'on');
   set(gcf,'WindowStyle','docked');
   set(0,'DefaultFigureWindowStyle','docked')
   %warning('off','all');
  end
  
 end
end