from setuptools import setup, find_packages

setup(
    name="adfcris",
    version="0.1.0",
    author="MB Jallow",
    author_email="mbjallow6@gmail.com",  # Optional: Update with your email
    description="A high-performance implementation of the ADFCRIS algorithm.",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/mbjallow6/Influence-Maximization-ADFCRIS",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Intended Audience :: Science/Research",
    ],
)
