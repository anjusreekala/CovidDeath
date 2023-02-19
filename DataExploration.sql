/*Data based on the countries*/
--count of countries in the data
SELECT continent, COUNT(DISTINCT location)
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent;

--countries in Europe
SELECT DISTINCT location, population
FROM PortfolioProject..CovidDeaths
WHERE continent = 'Europe'
ORDER BY population DESC;

--countries in Asia
SELECT DISTINCT location, population
FROM PortfolioProject..CovidDeaths
WHERE continent = 'Asia'
ORDER BY population DESC;

--countries in North America
SELECT DISTINCT location, population
FROM PortfolioProject..CovidDeaths
WHERE continent = 'North America'
ORDER BY population DESC;

--countries in Oceania
SELECT DISTINCT location, population
FROM PortfolioProject..CovidDeaths
WHERE continent = 'Oceania'
ORDER BY population DESC;

SELECT
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

--1)Total Cases Vs Total Deaths (Insight: North Korea has erraneous data)
SELECT
	location,
	continent,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float)) * 100,3) AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE total_deaths IS NOT NULL
ORDER BY 1 ;

--2)How much of the population got infected?
SELECT
	location,
	continent,
	date,
	total_cases,
	new_cases,
	population,
	ROUND(CAST(total_cases AS float) /CAST(population AS float) * 100,3) AS total_infected_population_pct
FROM PortfolioProject..CovidDeaths
WHERE continent IS  NOT NULL
ORDER BY total_infected_population_pct desc;

--3)How much of the population are newly infected?
--SELECT
--	location,
--	date,
--	total_cases,
--	new_cases,
--	population,
--	ROUND(CAST(new_cases AS float) /CAST(population AS float) * 100,4) AS newly_infected_population_pct
--FROM PortfolioProject..CovidDeaths
--ORDER BY newly_infected_population_pct DESC;

--4)Maximum infection count per location
SELECT
	location,
	continent,
	population,
	MAX(total_cases) AS max_total_cases,
	MAX(ROUND(CAST(total_cases AS float) /CAST(population AS float) * 100,3)) AS max_infection_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population,continent
ORDER BY max_infection_percentage DESC

--5)Countries with maximum death
SELECT
	location,
	continent,
	population,
	MAX(total_deaths) AS max_total_deaths,
	MAX(ROUND(CAST(total_deaths AS float) /CAST(population AS float) * 100,3)) AS max_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population,continent
ORDER BY max_total_deaths DESC;

/*Data based on the continents*/

--6)Continents with maximum death
SELECT
	continent,
	MAX(total_deaths) AS max_total_deaths,
	MAX(ROUND(CAST(total_deaths AS float) /CAST(population AS float) * 100,3)) AS max_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY max_total_deaths DESC;

-- 7)Data enetered without continent names, but listed under a continent name in column "location"
SELECT
	location,
	MAX(total_deaths) AS max_total_deaths,
	MAX(ROUND(CAST(total_deaths AS float) /CAST(population AS float) * 100,3)) AS max_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS  NULL
GROUP BY location
ORDER BY max_total_deaths DESC;


--8)Monthly case and death distribution
SELECT 
		YEAR(date) AS year ,
		DATENAME(month, date) AS month,
		SUM(new_cases) AS total_cases,
		SUM(new_deaths) AS total_deaths
FROM PortfolioProject..CovidDeaths
GROUP BY YEAR(date),DATENAME(month, date)
ORDER BY total_cases DESC


--9)Months with maximum death
SELECT * FROM (
				SELECT 
						YEAR(date) AS year_date ,
						DATENAME(month, date) AS month_date,
						SUM(new_deaths) sum_deaths,
						RANK() OVER(PARTITION BY YEAR(date) ORDER BY SUM(new_deaths) DESC) AS rnk
				FROM PortfolioProject..CovidDeaths
				GROUP BY YEAR(date),DATENAME(month, date)
) AS rank_table
WHERE rnk <= 3


--10)Month with Maximum hospital admission
/*
	DATA IS BIASED AS DATA FROM ALL OVER THE WORLD IS NOT REPORTED
*/
SELECT * FROM (
				SELECT 
						YEAR(date) AS year_date ,
						DATENAME(month, date) AS month_date,
						SUM(hosp_patients) total_hosp_admissions,
						RANK() OVER(PARTITION BY YEAR(date) ORDER BY SUM(hosp_patients) DESC) AS rnk
				FROM PortfolioProject..CovidDeaths
				GROUP BY YEAR(date),DATENAME(month, date)
) AS rank_table
WHERE rnk <= 3

--11)Locations with average maximum hospital admission
/*
	THE DATA IS INCOMPLETE AS MOST THIRD WORLD COUNTRIES HAS NOT UPDATED VALUES REGARDING THE HOSPITAL ADMISSIONS & ICU ADMISSIONS
*/
SELECT * FROM (
				SELECT 
						location,
						AVG( hosp_patients) as avg_admissions,
						DENSE_RANK() OVER(ORDER BY AVG(hosp_patients) DESC) AS rnk
				FROM PortfolioProject..CovidDeaths
				GROUP BY location
) AS rank_table
WHERE rnk <= 10


--12)total_tests
SELECT
		deaths.location,
		deaths.date,
		population,
		vaccine.total_tests
FROM PortfolioProject..CovidDeaths deaths
	INNER JOIN
	PortfolioProject..CovidVaccinations vaccine
ON deaths.continent = vaccine.continent
	AND deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE vaccine.total_tests IS NOT NULL
ORDER BY vaccine.total_tests DESC


--13)TEST PER CASE IN USA
SELECT 
		deaths.date,
		deaths.location,
		vaccine.tests_per_case
FROM PortfolioProject..CovidDeaths deaths
	INNER JOIN
	PortfolioProject..CovidVaccinations vaccine
ON deaths.continent = vaccine.continent
	AND deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE vaccine.tests_per_case IS NOT NULL
	 AND deaths.location = 'united states'
ORDER BY vaccine.tests_per_case DESC


--14) Vaccination Percentage in population Per Continent

WITH
VACCINATION_PCT_TBL AS(
						SELECT
								d.continent AS continent_name,
								YEAR(d.date) AS year_name,
								AVG(v.total_vaccinations) AS avg_vaccine,
								AVG(d.population) AS avg_population,
								cast(AVG(v.total_vaccinations) as float)/cast(AVG(d.population) as float)*100 AS pct_vaccine
						FROM PortfolioProject..CovidDeaths d 
							INNER JOIN PortfolioProject..CovidVaccinations v
						ON d.iso_code = v.iso_code 
							AND d.continent = v.continent
							AND d.location = v.location
							AND d.date = v.date
						WHERE v.total_vaccinations IS NOT NULL
							AND d.continent IS NOT NULL 
						GROUP BY d.continent,YEAR(d.date)
						--ORDER BY d.continent,YEAR(d.date)
),
RANK_TBL(continent,year_name,avg_vaccine,avg_population,pct_vaccine,rnk) AS(
				SELECT 
						*,
						DENSE_RANK() OVER(PARTITION BY continent_name ORDER BY pct_vaccine DESC) as rnk
				FROM VACCINATION_PCT_TBL
)
SELECT 
		continent,
		year_name,
		avg_vaccine,
		avg_population,
		pct_vaccine
FROM RANK_TBL
WHERE rnk = 1
ORDER BY pct_vaccine DESC

--15) CHECKING WHICH PART OF AFRICA IS SUFFERING FROM LACK OF VACCINATION MORE AS IT HAS LOWEST VACCINATION %
/* 47/56 i.e. ~84% OF THE COUNTRIES LISTED UNDER AFRICA ARE UNDERVACCINATED*/
WITH
AFRICAN_VACCINE_TBL AS(
						SELECT
								d.location AS location_name,
								YEAR(d.date) AS year_name,
								AVG(v.total_vaccinations) AS avg_vaccine,
								AVG(d.population) AS avg_population,
								cast(AVG(v.total_vaccinations) as float)/cast(AVG(d.population) as float)*100 AS pct_vaccine
						FROM PortfolioProject..CovidDeaths d 
							INNER JOIN PortfolioProject..CovidVaccinations v
						ON d.iso_code = v.iso_code 
							AND d.continent = v.continent
							AND d.location = v.location
							AND d.date = v.date
						WHERE v.total_vaccinations IS NOT NULL
							AND d.continent IS NOT NULL 
							AND d.continent = 'Africa'
						GROUP BY d.location,YEAR(d.date)
),
RNK_TBL AS(
			SELECT 
					*,
					RANK() OVER(PARTITION BY location_name ORDER BY pct_vaccine DESC) AS rnk
			FROM AFRICAN_VACCINE_TBL
)
SELECT
		location_name,
		year_name,
		avg_vaccine,
		avg_population,
		pct_vaccine
FROM RNK_TBL
WHERE rnk = 1
	AND pct_vaccine < 100
ORDER BY pct_vaccine ASC	  

--16)relation ship between population density and postive rate
/*there is no direct relationship between avg population density and avg positive rate as asia has much less positive rate with highest population density whereas
north america, europe, and south america has higher positive rate with relatively low pop density in order. South america has the lowest pop density, but highest positive rate
Africa has the lowest positive rate(can be contributed by under reporting too)*/
SELECT 
		continent,
		AVG(positive_rate) AS avg_positive_rate,
		AVG(population_density) AS avg_pop_density
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
	AND positive_rate IS NOT NULL
GROUP BY continent
ORDER BY avg_pop_density DESC

--17) Impact of stringency measures on deaths, new cases, reproduction rate and positive rate in North America
SELECT 
	v.date,
	MAX(v.positive_rate) AS max_poitive_rate,
	MAX(d.new_cases_smoothed) AS max_new_cases_smoothed,
	MAX(d.new_deaths_smoothed) AS max_new_deaths_smoothed,
	MAX(d.reproduction_rate) AS max_reproduction_rate,
	max(v.stringency_index) AS max_stringency_index
FROM PortfolioProject..CovidVaccinations v
	INNER JOIN 
	PortfolioProject..CovidDeaths d
ON d.iso_code = v.iso_code 
							AND d.continent = v.continent
							AND d.location = v.location
							AND d.date = v.date
WHERE stringency_index IS NOT NULL
AND v.continent = 'North America'
GROUP BY v.date
ORDER BY v.date

--18) percentage of ICU patients in hospital (Insight into the critical situations of the patient on infection)
/*
for "USA"
july, august, september, and october of 2020 saw max icu patients%

march - november of 2021 saw max icu patients in 2021

*/
SELECT 
		YEAR(date) AS year_name,
		DATENAME(month, date) AS month_name,
		MAX(icu_patients) AS max_icu_patients,
		MAX(hosp_patients) AS max_hosp_patients,
		ROUND(MAX(CAST(icu_patients AS float))/MAX(CAST(hosp_patients AS float)) *100, 2) AS pct_icu_patients_in_hosp
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
GROUP BY YEAR(date), DATENAME(month, date)
ORDER BY pct_icu_patients_in_hosp DESC


--Total Death Worldwide
SELECT location,
	   total_deaths
FROM PortfolioProject..CovidDeaths
WHERE total_deaths IS NOT NULL;

--Total Cases Worldwide
SELECT location,
	   total_cases
FROM PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL;


--Total people fully vaccinated
SELECT 
		date,
		sum(people_fully_vaccinated) AS vaccinated_people
FROM PortfolioProject..CovidVaccinations 
WHERE people_fully_vaccinated IS NOT NULL 
GROUP BY date		
ORDER BY sum(people_fully_vaccinated)




select sum(max_pop) from(
SELECT continent, sum(population) as max_pop from PortfolioProject..CovidDeaths  where continent is not null group by continent) tbl_pop

--total vaccine per location

WITH 
location_tbl AS (
					SELECT 
							v.location,
							v.continent,
							YEAR(v.date) AS year_date,
							AVG(v.total_vaccinations) AS avg_vaccine,
							AVG(d.population) AS avg_population,
							cast(AVG(v.total_vaccinations) as float)/cast(AVG(d.population) as float)*100 AS pct_vaccine_location
					FROM PortfolioProject..CovidVaccinations v
						INNER JOIN
						PortfolioProject..CovidDeaths d
					ON d.iso_code = v.iso_code 
						AND d.continent = v.continent
						AND d.location = v.location
						AND d.date = v.date
					WHERE v.total_vaccinations IS NOT NULL
					GROUP BY v.location,v.continent,YEAR(v.date)

				),
rnk_tbl AS(
			SELECT
					*,
					RANK() OVER(PARTITION BY location ORDER BY pct_vaccine_location DESC) AS rnk
			FROM location_tbl
			)
SELECT * 
FROM rnk_tbl
WHERE rnk = 1