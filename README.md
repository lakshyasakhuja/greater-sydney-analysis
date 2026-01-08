# Greater Sydney Spatial Analysis using PostGIS and Python

This repository contains my **DATA2001 (Data Science, Big Data & Data Diversity)** project from the **University of Sydney (Semester 2)**, implemented using **Python, PostgreSQL, and PostGIS**.

This project focuses on analysing **Greater Sydney** using real-world spatial datasets, combining **relational databases**, **geospatial data**, and **data science workflows** to extract meaningful insights through spatial joins, aggregation, and analysis.

---

## 📘 Project Overview

At a high level, this project demonstrates how **large-scale spatial data** can be integrated, processed, and analysed using database-backed workflows rather than in-memory analysis alone.

The project explores:

- Loading and managing spatial datasets in **PostgreSQL with PostGIS**
- Performing **spatial joins and aggregations** across geographic regions
- Using **Python and Jupyter Notebooks** to orchestrate database workflows
- Combining SQL-based analysis with programmatic data pipelines
- Producing reproducible, structured analytical outputs

The emphasis is on **data engineering and spatial reasoning**, rather than purely statistical modelling.

---

## 🌏 Analytical Focus & Motivation

Modern data science often involves datasets that are:
- Too large for simple CSV-based workflows
- Spatial in nature (locations, regions, boundaries)
- Better processed inside databases rather than in memory

This project was motivated by the need to:
- Work with **geospatial data at scale**
- Understand how **relational databases and spatial extensions** support data science
- Apply **database-first thinking** to analytical problems
- Build workflows that reflect real-world industry practices

By using PostGIS, the project highlights how spatial databases enable efficient and expressive geospatial analysis.

---

## 🧠 Analytical & Technical Approach

The project follows a **database-centred data science pipeline**:

- Data is stored and managed inside **PostgreSQL**
- **PostGIS geometry types** are used for spatial representation
- Spatial operations (e.g. containment, proximity, joins) are executed using SQL
- **Python (Jupyter Notebook)** is used to:
  - Manage connections
  - Trigger queries
  - Validate results
  - Document the analysis process

This approach mirrors how spatial analytics is commonly handled in industry and government environments.

---

## 🧾 Workflow & Execution

The analysis is driven through a **Jupyter Notebook**, which acts as the central orchestration layer.

Key workflow components include:

- A local **PostgreSQL + PostGIS** database
- A configuration file (`db.json`) for database credentials (excluded from GitHub)
- SQL queries executed against spatial tables
- Outputs validated and discussed within the notebook
- A final written report summarising findings and methodology

This setup promotes:
- Reproducibility
- Separation of configuration and logic
- Secure handling of credentials
- Clear documentation of each analytical step

---

## 📂 Repository Structure

```text
project_root/
├── data2001 project.ipynb
├── DATA2001 Project Report.pdf
├── db.json.example
├── .gitignore
└── README.md
````

* `data2001 project.ipynb`
  Main notebook containing the analysis workflow and database interactions.

* `DATA2001 Project Report.pdf`
  Final academic report submitted for assessment.

* `db.json.example`
  Template showing the expected database configuration format.

---

## 🧠 Key Learnings

* Designing **database-driven data science workflows**
* Using **PostGIS** for spatial joins and geographic analysis
* Integrating **SQL and Python** in a single analytical pipeline
* Managing credentials and configuration securely
* Working with spatial datasets in a scalable, industry-relevant manner
* Translating technical analysis into clear written reporting

---

## 🛠 Tools & Technologies

* **Python**
* **Jupyter Notebook**
* **PostgreSQL**
* **PostGIS**
* **SQL**
* **Geospatial Data Analysis**
* **Database-Centred Data Science**

---

## 📝 Significance

This project strengthened my ability to work at the intersection of:

* Databases
* Geospatial analysis
* Data science pipelines

It represents a shift from small, file-based analysis to **scalable, database-backed analytics**, laying the groundwork for more advanced data engineering and spatial data projects.

---

## 🎓 Course Information

* **University:** The University of Sydney
* **Unit:** DATA2001 – Data Science, Big Data and Data Diversity
* **Assessment Type:** Group Project
* **Semester:** Semester 2

Just tell me the next step.
```
