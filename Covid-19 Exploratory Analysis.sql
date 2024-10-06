USE portfolioproject;

UPDATE coviddeath
SET date = DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%Y'), '%Y-%m-%d');

ALTER TABLE coviddeath
MODIFY COLUMN date DATE;

UPDATE covidvaccination
SET date = DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%Y'), '%Y-%m-%d');

ALTER TABLE covidvaccination
MODIFY COLUMN date DATE;

SELECT 
	location, date, total_cases, new_cases, total_deaths, population
FROM	
	coviddeath
WHERE continent <> ' '
ORDER BY 1,2;


### Likelihood of dying from covid in UK
SELECT 
	 location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM	
	coviddeath
WHERE location = 'United Kingdom'
ORDER BY 1,2;

### Total cases against population

SELECT 
	 location, date, population, total_cases, (total_cases/population)*100 AS covidcasepercentage
FROM	
	coviddeath
WHERE location = 'United Kingdom'
ORDER BY 1,2;


### Country with highest infection rate

SELECT 
	 location, population, MAX(total_cases) AS highestinfectedcount, (MAX(total_cases)/population)*100 AS highestinfectedcountry
FROM	
	coviddeath
GROUP BY location, population
ORDER BY highestinfectedcountry DESC;

### Highest Death Count

SELECT 
	 location, MAX(CAST(total_deaths AS SIGNED)) AS deathcount
FROM	
	coviddeath
WHERE continent <> ''
GROUP BY location
ORDER BY deathcount DESC;

### Highest Death Count by continent

SELECT 
	 location, MAX(CAST(total_deaths AS SIGNED)) AS deathcount
FROM	
	coviddeath
WHERE continent = ''
GROUP BY location
ORDER BY deathcount DESC;

SELECT 
	 continent, MAX(CAST(total_deaths AS SIGNED)) AS deathcount
FROM	
	coviddeath
WHERE continent <> ''
GROUP BY continent
ORDER BY deathcount DESC;


### Global numbers
SELECT
	 SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS deathpercentage
 FROM	
	coviddeath
WHERE continent <> ''
###GROUP BY date
ORDER BY 1,2;


### Using join, total population versus total vaccinated

SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS SIGNED))
    OVER(PARTITION BY cd.location ORDER BY cv.location, cv.date) AS total_vaccinated
FROM
    coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date
WHERE
    cd.continent <> ''
ORDER BY 2 , 3;

### Using join, total population versus total vaccinated...CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, total_vaccinated) AS
(
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS SIGNED))
    OVER(PARTITION BY cd.location ORDER BY cv.location, cv.date) AS total_vaccinated
FROM
    coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date
WHERE
    cd.continent <> ''
ORDER BY 2 , 3)
SELECT *, total_vaccinated/population*100
FROM popvsvac;


### Duplicating my data
CREATE TABLE coviddeath2 AS
SELECT * FROM coviddeath;

CREATE TABLE covidvaccination2 AS
SELECT * FROM covidvaccination;

#Temporary Table


DROP TEMPORARY TABLE IF EXISTS vaccinated_population_percent;

CREATE TEMPORARY TABLE vaccinated_population_percent
(
continent VARCHAR(255),
location VARCHAR(255),
date DATE, 
population TEXT,
new_vaccinations TEXT,
total_vaccinated FLOAT
);
INSERT INTO vaccinated_population_percent
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cv.location, cv.date) AS total_vaccinated
FROM
    coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date;
#####WHERE cd.continent <> ''
#####ORDER BY 2 , 3;
SELECT *, total_vaccinated/population*100 
FROM vaccinated_population_percent;


### Creating view to store data for later visualization

CREATE VIEW percentpopulationvaccinated AS
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cv.location, cv.date) AS total_vaccinated
FROM
    coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date
WHERE cd.continent <> '';
####ORDER BY 2 , 3;

SELECT *
FROM percentpopulationvaccinated;