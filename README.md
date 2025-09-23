# Advanced Distributed Fair-Competitive RIS (ADFCRIS)

This repository contains the source code and research materials for the ADFCRIS project, a high-performance implementation of advanced influence maximization algorithms. The project is designed for scalability and reproducibility, with a fully automated setup process.

---
## Table of Contents
* [Features](#features)
* [Prerequisites](#prerequisites)
* [Setup & Installation](#setup--installation)
* [How to Use the Project](#how-to-use-the-project)
* [Development Workflow](#development-workflow)
* [Project Structure](#project-structure)
* [Contributing](#contributing)
* [License](#license)

---
## Features
* **Automated Setup**: A single script sets up the entire development environment, including all dependencies.
* **Hardware-Aware**: The setup automatically detects if you have an NVIDIA GPU and installs the appropriate packages for either GPU or CPU-only operation.
* **Reproducible Environment**: Uses Conda and a lock file to ensure that the environment can be perfectly recreated, which is essential for reproducible research.
* **Automated Workflow**: Includes a powerful script to automate daily Git and GitHub tasks like creating branches, saving work, and making pull requests.
* **Built-in Quality Control**: Code formatting and linting tools are integrated and run automatically before every commit to maintain high code quality.

---
## Prerequisites
Before you begin, you need to have two pieces of software installed on your computer.

1.  **Git**: A version control system used to download and manage the code.
    * [Download Git here](https://git-scm.com/downloads)

2.  **Miniconda (or Anaconda)**: A package and environment manager. We strongly recommend **Miniconda**.
    * [Download Miniconda here](https://docs.conda.io/en/latest/miniconda.html)

---
## Setup & Installation
This project uses a single script to handle the entire setup process. Follow these steps carefully.

**1. Clone the Repository**
First, download the project code to your computer. Open your terminal, navigate to where you want to store the project, and run this command:
```bash
git clone [https://github.com/mbjallow6/Influence-Maximization-ADFCRIS.git](https://github.com/mbjallow6/Influence-Maximization-ADFCRIS.git)
```

**2. Navigate into the Project Directory**
```bash
cd Influence-Maximization-ADFCRIS
```

**3. Run the Setup Script**
This is the main step. The script will automatically detect your hardware, create a dedicated `adfcris` Conda environment, and install all the necessary Python packages.

**This process will take a significant amount of time (15-30 minutes or more) depending on your internet connection.** Please be patient.
```bash
bash scripts/adfcris-setup.sh
```

**4. Activate the Conda Environment**
Once the setup is complete, you must "activate" the project's environment. This makes all the installed tools and libraries available to you. You'll need to do this every time you open a new terminal to work on the project.
```bash
conda activate adfcris
```

**5. Install the Project Package**
This final command makes your source code in the `src/` folder available as an installable package.
```bash
make install
```
Your project is now fully set up and ready to use!

---
## How to Use the Project
After setting up, you can use the `Makefile` to perform common actions. Make sure your `adfcris` environment is active first.

* **To run the test suite**:
    ```bash
    make test
    ```
* **To start a Jupyter Lab session for writing notebooks**:
    ```bash
    make jupyter
    ```
* **To automatically format your code**:
    ```bash
    make format
    ```

---
## Development Workflow
To contribute code, use the `adfcris-workflow.sh` script. It simplifies the entire process.

**1. Start a New Feature**
Let's say you want to work on a feature called `new-sampling-method`.
```bash
./scripts/adfcris-workflow.sh feature new-sampling-method
```
This creates a new branch for you called `feature/new-sampling-method`.

**2. Write Your Code**
Make your changes to the project files using your favorite code editor.

**3. Save Your Work**
When you've made some progress, save it with a descriptive message. This commits your code and pushes it to GitHub.
```bash
./scripts/adfcris-workflow.sh save "Implement the first part of the sampler"
```

**4. Create a Pull Request**
When your feature is ready for review, create a pull request. This will run the tests automatically before creating the PR on GitHub.
```bash
./scripts/adfcris-workflow.sh pr "feat: Implement new sampling method"
```

**5. Merge Your Feature**
After your pull request is approved and merged on GitHub, run the `complete` command. It will merge the changes and clean up your local and remote branches.
```bash
./scripts/adfcris-workflow.sh complete
```

---
## Project Structure
```
├── data/             # Raw and processed data
├── docs/             # Project documentation
├── experiments/      # Experiment scripts and configuration
├── notebooks/        # Jupyter notebooks for exploration and analysis
├── scripts/          # Helper scripts (setup, workflow, etc.)
├── src/adfcris/      # Main Python source code for the project
├── tests/            # Test suite for the source code
├── environment-gpu.yml # Conda environment for GPU systems
├── environment-cpu.yml # Conda environment for CPU-only systems
├── Makefile          # Automation commands
└── README.md         # You are here
```

---
## Contributing
Contributions are welcome! Please follow the [Development Workflow](#development-workflow) to create a pull request.

---
## License
This project is licensed under the MIT License.
