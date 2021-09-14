SELECT * 
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, population, total_deaths
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
ORDER BY 1,2;

--Comparing total cases to deaths in the United States. This is an estimation of the likelihood of dying if one is infected with COVID-19 and lives in the US.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Percentage
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
WHERE location LIKE '%states%'
ORDER BY 1,2;

--Comparing total cases vs. Population, shows the percentage of people who have contracted COVID-19

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentageInfected
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
WHERE location LIKE '%states%'
ORDER BY 2;

--Looking at highest infection rates of countries
SELECT location, MAX(total_cases) as MaxInfectionCount, population, (MAX(total_cases)/population)*100 AS PercentageInfected
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PercentageInfected DESC;

--Looking at highest infection vs. deaths of countries
SELECT location, MAX(total_cases) as MaxInfectionCount, MAX(total_deaths) AS MaxDeathsOfInfected, population, 
(MAX(total_cases)/population)*100 AS PercentageInfected, (MAX(total_deaths)/MAX(total_cases)) AS MaxInfectedDeaths

FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PercentageInfected DESC;

--Looking at countries with the highest death counts relative to population

SELECT location, MAX(cast(total_Deaths as int)) as TotalDeathCount
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Finding continents with highest death count
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC;



SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--visualization info begins here, reoplace any of the above queries with CONTINENT
--world descriptive info


SELECT SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null
--GROUP BY date
ORDER BY 1,2;

--WORLD DEATH PERCENTAGE
SELECT date, SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolio..covid_DeathsCleaned$
WHERE continent IS NOT null

ORDER BY 1,2;

SELECT *
FROM CovidPortfolio..covid_DeathsCleaned$ dea
JOIN CovidPortfolio..covid_VacsCleaned$ vac
	ON dea.location = vac.location
	and dea.date = vac.date;

--Taking a look at new vaccinations and taking a rolling count of new vaccinations by location via partition

WITH PopVsVacs (continent, location, date, population, new_vaccinations, RollingVaccinations)
as
(

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM CovidPortfolio..covid_DeathsCleaned$ dea
JOIN CovidPortfolio..covid_VacsCleaned$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT null

)



SELECT *, (RollingVaccinations/population)*100 FROM PopVsVacs

--Using CTE so that we can perform further calculations

DROP TABLE IF EXISTS #PercentPopVaxxed
CREATE TABLE #PercentPopVaxxed
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinations numeric
)

INSERT INTO  #PercentPopVaxxed
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM CovidPortfolio..covid_DeathsCleaned$ dea
JOIN CovidPortfolio..covid_VacsCleaned$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *, (RollingVaccinations/population)*100 FROM #PercentPopVaxxed



--Creating VIEW to store data for visualizations


CREATE VIEW PercentPopVaxxed as

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM CovidPortfolio..covid_DeathsCleaned$ dea
JOIN CovidPortfolio..covid_VacsCleaned$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT * FROM PercentPopVaxxed