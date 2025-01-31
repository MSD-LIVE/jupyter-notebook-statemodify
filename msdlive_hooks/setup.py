# setup.py
from setuptools import setup, find_packages

setup(
    name='msdlive_plugin',
    version='0.1',
    packages=find_packages(),
    entry_points={
        'msdlive_extension.activate_hook': [
            'copy_to_home = msdlive_hooks:activate',  # Reference to the activate function in my_plugin.py
        ],
    },
)
