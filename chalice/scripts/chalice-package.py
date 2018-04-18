# Package chalice app into zip file

import argparse
import os
import shutil
import glob
import subprocess

def package(app_name):
    # Make directory to store all the packages
    try:
        os.mkdir("dist")
    except FileExistsError:
        pass

    # Helper to run packaging:
    def package_single(app_name):
        curdir = os.path.abspath(os.curdir)
        try:
            app_dir = os.path.join(curdir, app_name)
            app_dist_dir = os.path.join(curdir, "dist", app_name)

            try:
                shutil.rmtree(app_dist_dir)
            except FileNotFoundError:
                pass
            
            os.mkdir(app_dist_dir)
            os.chdir(app_dir)
            subprocess.call(('chalice','package',app_dist_dir))
            
        finally:
            os.chdir(curdir)

    if app_name is None:
        # No app was specified, so package all of the apps found in the
        # chalice/ directory.
        for fn in glob.iglob('*/app.py'):
            package_single(os.path.split(fn)[0])
    else:
        package_single(app_name)
    
def main():
    parser = argparse.ArgumentParser(description='Package chalice app')
    parser.add_argument('app', nargs="?", help='The chalice app directory', default=None)
    args = parser.parse_args()
    package(args.app)
    
if __name__ == '__main__':
    main()
