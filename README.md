# ⚽ LPF Database (Liga Panameña de Fútbol)

PostgreSQL database for the **Liga Panameña de Fútbol (LPF)**, including schema, sample data, and views for queries like standings and match information.

---

## 📌 Project Description
This project models the main entities of the LPF, such as:
- Teams (equipos)
- Matches (partidos)
- Stadiums (estadios)
- Conferences (conferencias)
- Phases (fases)
- Seasons (temporadas)
- Tournaments (torneos)

It also includes constraints, indexes, and roles for better performance and security.

---

## 🗂️ Database Schema (ERD)
👉 *(Insert your diagram image here, e.g. `![ERD](diagram.png)`)*

---

## 📂 Database Contents

The `lpf_database.sql` export includes the following:

### 🗄️ Tables
- **equipos** → Teams information (name, city, stadium, conference, foundation date)  
- **partidos** → Matches between teams (date, goals, stadium, phase, type of match)  
- **estadios** → Stadium details (name, location, capacity)  
- **fases** → Tournament phases (classification, repechaje, semifinal, final)  
- **conferencias** → League conferences (East/West)  
- **temporadas** → Seasons (year)  
- **torneos** → Tournaments linked to seasons (Apertura, Clausura)  

### 👀 Views
- **goles_equipo_vista** → Goals scored/conceded per team  
- **tabla_posiciones_vista** → Standings (points, wins, draws, losses, GD) by conference  
- **partidos_info_vista** → Match details with teams, result, stadium, and phase  

### 🔐 Constraints
- Primary keys (`id` in each table)  
- Foreign keys (relationships between equipos, conferencias, estadios, torneos, fases, partidos)  
- Check constraints (e.g., no negative goals, local team ≠ visiting team)  
- Unique constraints (unique team names, stadium names, season year, etc.)  

### ⚡ Indexes
- `equipos_nombre_idx` → quick search by team name  
- `partidos_equipo_local_id_idx` → filter by home team  
- `partidos_equipo_visitante_id_idx` → filter by away team  
- `partidos_fase_id_idx` → filter by phase  
- `partidos_jornada_idx` → filter by matchday  

### 👥 Roles & Permissions
- **readonly** → can only view data  
- **readwrite** → can view, insert, update, and delete data  

---

## 🚀 How to Import

1. Clone this repository or download the `.sql` file.  
2. Create a new database in PostgreSQL (e.g., `lpf`).  
3. Import the dump using `psql`:  

```bash
psql -U postgres -d lpf -f lpf_database.sql

