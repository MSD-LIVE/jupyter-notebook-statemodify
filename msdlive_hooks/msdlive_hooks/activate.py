import os
import shutil


def activate(server_app=None):
    """
    From inside the user's home directory:
    1. Checks if a symlink named 'data' exists:
       - If it exists, removes the symlink and prints a message.
       - If it does not exist, prints a message indicating that it is not a symlink.
    2. Creates a new directory named 'data' if it does not already exist.
    3. Defines a function `copy_function` to copy files from source to destination if the destination
       does not exist or if the source file is newer than the destination file.
    4. Copies everything from '/data/example' to the new 'data' directory,
       except the input directory is symlink'd, as it can be read-only and is very large.
    """
    server_app.log.info(f"Plugin has been activated! server_app {server_app}")
    
    symlink_path = 'data'
    if os.path.islink(symlink_path):
        os.unlink(symlink_path)
        server_app.log.info(f"Symlink '{symlink_path}' has been removed.")
    else:
        server_app.log.info(f"'{symlink_path}' is not a symlink.")
    
    # Create a new directory named 'data' in user's home dir
    os.makedirs(symlink_path, exist_ok=True)
    server_app.log.info(f"Directory '{symlink_path}' has been created.")

    def copy_function(src, dst):
        if not os.path.exists(dst) or os.path.getmtime(
            src
        ) > os.path.getmtime(dst):
            shutil.copy2(src, dst)
    
    # Recursively copy everything from '/data' to the new 'data' directory EXCEPT the input dir
    # because the input dir can be read only and is very large
    source_path = '/data'
    dest_path = "data"
    
    if not os.path.exists(source_path):
        server_app.log.error(f"Source directory '{source_path}' does not exist.")
        return

    shutil.copytree(
        source_path,
        dest_path,
        copy_function=copy_function,
        dirs_exist_ok=True,
    )
