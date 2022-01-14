/* 
	Data was sourced from ourworldindata.org
*/

SELECT *
FROM PortfolioProject..Covid_Deaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..Covid_Vaccinations
ORDER BY 3,4

-- Select the data that we're going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population, hosp_patients
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT location, date, people_fully_vaccinated, aged_65_older, diabetes_prevalence
FROM PortfolioProject..Covid_Vaccinations

/*
	BREAKING THINGS DOWN FOR THE U.S.
*/

-- Total Cases vs Total Deaths
-- Shows likelihood of dying from COVID-19 in the U.S
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_chance
FROM PortfolioProject..Covid_Deaths
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Population
-- Shows percentage of population that contracted COVID-19 in the U.S
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS percent_infected
FROM PortfolioProject..Covid_Deaths
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Hospitalized Patients
-- Shows percentage of confirmed cases that led to hospitalization in the U.S 
SELECT location, date, total_cases, hosp_patients, (hosp_patients/total_cases) * 100 AS percent_hospitalized
FROM PortfolioProject..Covid_Deaths
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

/*
	BREAKING THINGS DOWN BY COUNTRY
*/

-- Countries with highest infection rate
SELECT location, population, MAX(total_cases) AS max_cases, MAX((total_cases/population)) * 100 AS percent_infected
FROM PortfolioProject..Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_infected DESC

-- Countries with highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS max_death
FROM PortfolioProject..Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_death DESC

/*
	BREAKING THINGS DOWN BY CONTINENT
*/

-- Continents with highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS max_death
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NULL
AND NOT (location LIKE '%income%' OR location LIKE '%World%' OR location LIKE '%International' OR location LIKE '%Union%')
/* Another way to write this part would be:
AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
*/
GROUP BY location
ORDER BY max_death DESC

-- Continents with highest infection rate
SELECT location, SUM(population) as continental_population, SUM(total_cases) AS max_cases, MAX((total_cases/population)) * 100 AS percent_infected
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NULL
AND NOT (location LIKE '%income%' OR location LIKE '%World%' OR location LIKE '%International' OR location LIKE '%Union%')
GROUP BY location
ORDER BY percent_infected DESC

-- GLOBAL NUMBERS

-- Global death percentage
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Global death percentage by date
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global death percentage by income
SELECT location, MAX(total_cases) as new_total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage_income
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NULL
AND location LIKE '%income%'
GROUP BY location
ORDER BY death_percentage_income DESC

/*
	JOINING TABLES
*/

-- Total Population vs New Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 1,2,3

-- using common table expression (CTE) to calculate percentage of population that has received at least 1 vaccine
WITH PopvsVacc (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
--AND deaths.location LIKE '%states%'
--ORDER BY 1,2,3
)
SELECT *, (rolling_vaccinations/population)*100 AS percentage_vaccinated
FROM PopvsVacc

-- Same as previous query except using temp table
DROP TABLE IF EXISTS #PercentVaccinated
CREATE TABLE #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #PercentVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
--WHERE deaths.continent IS NOT NULL
--ORDER BY 1,2,3

SELECT *, (rolling_vaccinations/population)*100 AS percentage_vaccinated
FROM #PercentVaccinated

-- Total Population vs Fully Vaccinated as of latest date recorded
-- Shows percentage of population that is fully vaccinated as of latest date recorded
SELECT deaths.location, deaths.date, deaths.population, vacc.people_fully_vaccinated, (vacc.people_fully_vaccinated/deaths.population) * 100 AS percentage_fully_vaccinated
FROM PortfolioProject..Covid_Deaths AS deaths
INNER JOIN (
	SELECT location, MAX(date) AS latest_date
	FROM PortfolioProject..Covid_Deaths
	GROUP BY location
) AS latest_deaths
ON deaths.location = latest_deaths.location AND deaths.date = latest_deaths.latest_date
JOIN PortfolioProject..Covid_Vaccinations as vacc
ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY percentage_fully_vaccinated DESC

-- similar to previous quiery except ensuring that the date is 4 January 2022, which is when dataset was downloaded
SELECT deaths.location, deaths.population, vacc.people_fully_vaccinated, (vacc.people_fully_vaccinated/deaths.population) * 100 AS percentage_fully_vaccinated
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations as vacc
ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
AND deaths.date = '2022-01-04 00:00:00.000'
ORDER BY percentage_fully_vaccinated DESC

-- Shows change in percentage of fully vaccinated people over time
SELECT deaths.location, deaths.date, deaths.population, vacc.people_fully_vaccinated, (vacc.people_fully_vaccinated/deaths.population) * 100 AS percentage_fully_vaccinated
FROM PortfolioProject..Covid_Deaths AS deaths
--INNER JOIN (
--	SELECT location, MAX(date) AS latest_date
--	FROM PortfolioProject..Covid_Deaths
--	GROUP BY location
--) AS latest_deaths
--ON deaths.location = latest_deaths.location AND deaths.date = latest_deaths.latest_date
JOIN PortfolioProject..Covid_Vaccinations as vacc
ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
--AND deaths.location like '%states%'
--ORDER BY percentage_fully_vaccinated DESC

-- Average Population vs Average Risk Population
-- Shows an estimated number of people that are considered at risk for severe COVID-19 infection (people with diabetes and people aged 65+)
WITH RiskPop (location, avg_pop, avg_diabetes_pop, avg_65_older_pop)
AS (
SELECT deaths.location, AVG(deaths.population) as avg_pop, AVG((deaths.population*vacc.diabetes_prevalence)/100) AS avg_diabetes_pop, AVG((deaths.population*vacc.aged_65_older)/100) AS avg_65_older_pop
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations AS vacc
	ON deaths.location = vacc.location
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.location
--ORDER BY 1,2,3
)
SELECT *, (avg_diabetes_pop + avg_65_older_pop) AS risk_pop, ((avg_diabetes_pop + avg_65_older_pop)/avg_pop)*100 AS percent_risk
FROM RiskPop
ORDER BY percent_risk DESC

/*
	Creating view to store data for visualizations
*/

Create View PercentVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..Covid_Deaths AS deaths
JOIN PortfolioProject..Covid_Vaccinations AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 1,2,3
