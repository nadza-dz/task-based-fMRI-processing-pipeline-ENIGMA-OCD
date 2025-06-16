# N, Dzinalija Jan 2024
# Script to create subcortical figure views in MRIcroGL, can only be run on Remote Desktop in MRIcroGL, not Luna.
# This script needs to be copy-pasted into MRIcroGL>Scripting and run  by command+R
# Remember to resize window to a (small) square so that the output figure is a little nicer, 
# as the script essentially takes a screenshot of the viewing window in MRIcroGL
# To obtain the coloring used in RBA, there is a rbacol.clut file that should be in the same directory as 
# this script and should be pasted into the \MRIcron\Resources\lut folder to make it findable by the script 

import gl

contrasts = ['PLANNING', 'LOAD']
models = ['YBOCS', 'AO', 'MED', 'BASE']
tasks = ['', 'TOL_only']
sides = ['left', 'right']

base_path = 'C:\\Users\\P078744\\OneDrive - Amsterdam UMC\\Documents\\ENIGMA-OCD\\Temp\\Whole_brain\\Schaefer200'

for contrast in contrasts:
    for model in models:
        if model == 'AO':
            submodels = ['Adult-vs-Child', 'Child-vs-HC', 'Adult-vs-HC']
        elif model == 'MED':
            submodels = ['Med-vs-Unmed', 'Unmed-vs-HC', 'Med-vs-HC']
        elif model == 'BASE':
            submodels = ['Intercept','Dx-OCD-vs-HC']
        else:
            submodels = [None]  

        for submodel in submodels:
            for task in tasks:
                for side in sides:
                    gl.resetdefaults()

                    if task == "TOL_only":
                        task_path = "\\TOL_only"
                    else:
                        task_path = ""
                    
                    if model == 'BASE':
                        filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{submodel}_Melbourne32_3D.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path, submodel=submodel
                        )
                        overlay_filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{submodel}_Melbourne32_3D_{side}.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path, submodel=submodel, side=side
                        )
                    elif model == 'YBOCS':
                        filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{model}_Melbourne32_3D.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path
                        )
                        overlay_filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{model}_Melbourne32_3D_{side}.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path, side=side
                        )
                    else:
                        filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{model}-{submodel}_Melbourne32_3D.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path, submodel=submodel
                        )
                        overlay_filename = "{base_path}\\{contrast}\\{model}{task_path}\\Subcortical\\{contrast}_{model}-{submodel}_Melbourne32_3D_{side}.nii.gz".format(
                            base_path=base_path, contrast=contrast, model=model, task_path=task_path, submodel=submodel, side=side
                        )

                    gl.loadimage(filename)
                    gl.overlayload(overlay_filename)  
                    gl.minmax(0, 1, 5)
                    gl.minmax(1, 0, 1) 
                    gl.colorname(1, "rbacol")
                    gl.shadername('Glass')
                    gl.backcolor(255, 255, 255)
                    gl.zerointensityinvisible(1,1)
                    gl.viewsagittal(0)
                    gl.bmpzoom(2)
                    gl.savebmp(overlay_filename + '_view1.jpg')
                    gl.viewsagittal(1)
                    gl.bmpzoom(2)
                    gl.savebmp(overlay_filename + '_view2.jpg')
