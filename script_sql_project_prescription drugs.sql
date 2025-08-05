-- ## Prescribers Database
SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM drug;

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- Answer: 1356305197, 379

SELECT DISTINCT pr.npi, SUM(total_claim_count) AS total_claim_count
FROM prescriber AS pr
INNER JOIN prescription AS rx
USING (npi)
GROUP BY pr.npi
ORDER BY total_claim_count DESC;

 
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
-- Answer: Michael Cox, 379

--NEED change this 

SELECT DISTINCT pr.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, COUNT (total_claim_count) AS total_claim_count
FROM prescriber AS pr
INNER JOIN prescription AS rx
USING (npi)
GROUP BY pr.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
ORDER BY total_claim_count DESC;


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT pr.specialty_description, SUM(total_claim_count) AS total_claim_count
FROM prescriber AS pr
INNER JOIN prescription AS rx
USING (npi)
GROUP BY pr.specialty_description
ORDER BY total_claim_count DESC;


--     b. Which specialty had the most total number of claims for opioids?
-- opioid_claim_count see "Additional Information" in the pdf
SELECT *
FROM prescription;

SELECT *
FROM drug
WHERE opioid_drug_flag = 'Y';

SELECT DISTINCT pr.specialty_description, SUM(total_claim_count) AS total_opioid_claim_count
FROM prescriber AS pr
INNER JOIN prescription AS rx
USING (npi)
INNER JOIN drug AS d
ON rx.drug_name = d.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY pr.specialty_description
ORDER BY total_opioid_claim_count DESC;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
-- NEED

SELECT DISTINCT pr.specialty_description, SUM(total_claim_count) AS total_claim_count
FROM prescriber AS pr
LEFT JOIN prescription AS rx
USING (npi)
GROUP BY pr.specialty_description
HAVING SUM(total_claim_count) IS NULL;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
-- NEED

SELECT 
	specialty_description
	,(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END))/SUM(total_claim_count)) * 100
AS percent_opioid
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid DESC NULLS LAST;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT *
FROM drug;

SELECT *
FROM prescription;

SELECT d.generic_name, SUM(rx.total_drug_cost)::MONEY AS total_drug_cost
FROM drug AS d
	INNER JOIN prescription AS rx
	ON rx.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY total_drug_cost DESC;

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

-- NEED

SELECT generic_name, ROUND((rx.total_drug_cost)/SUM(total_day_supply),2) AS daily_drug_cost
FROM drug AS d
	INNER JOIN prescription AS rx
	ON rx.drug_name = d.drug_name
GROUP BY d.generic_name, rx.total_drug_cost
ORDER BY total_drug_cost DESC;


-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT *
FROM drug;


SELECT drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;


--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
-- Answer: opioids

SELECT drug_type, SUM(rx.total_drug_cost::MONEY) AS total_drug_cost
FROM 
	(SELECT drug_name,
		CASE 
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type
	FROM drug) AS something
INNER JOIN prescription AS rx
USING (drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- I searched for TN only, not where it lists more than 1 state with TN
-- Answer: 6
SELECT *
FROM cbsa;

SELECT COUNT (DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';

--     b. Which cbsa has the largest combined population? Memphis, TN-MS-AR
-- Which has the smallest? Knoxville, TN
-- Report the CBSA name and total population.

SELECT *
FROM cbsa;

SELECT cbsaname, TO_CHAR(SUM(population), 'FM9,999,999') AS population
FROM cbsa
INNER JOIN population 
USING (fipscounty)
GROUP BY cbsaname
ORDER BY population DESC;

SELECT cbsaname, TO_CHAR(SUM(population), 'FM9,999,999') AS population
FROM cbsa
INNER JOIN population 
USING (fipscounty)
GROUP BY cbsaname
ORDER BY population ASC;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT *
FROM cbsa;

SELECT *
FROM fips_county;

-- NEED something to determine when the county is not in cbsa

SELECT county, population
FROM cbsa
INNER JOIN fips_county 
USING (fipscounty) 
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC;

INNER JOIN population AS p
USING (fipscounty)

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT *
FROM prescription;

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT *
FROM drug;

SELECT drug_name, opioid_drug_flag, total_claim_count
FROM prescription 
INNER JOIN drug 
USING (drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT *
FROM prescriber;

SELECT nppes_provider_last_org_name AS last_org_name, nppes_provider_first_name AS first_name, drug_name, opioid_drug_flag, total_claim_count
FROM prescription AS rx
INNER JOIN drug AS d
USING (drug_name)
INNER JOIN prescriber AS p
USING (npi)
WHERE total_claim_count >= 3000
ORDER BY last_org_name;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM drug;

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT *
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- NEED: not getting all drug_name for each provider. Should have null values for some drug_name for some providers. 

SELECT p.specialty_description, p.nppes_provider_last_org_name AS last_org_name, rx.npi, rx.drug_name, total_claim_count 
FROM prescription AS rx
	FULL JOIN prescriber AS p
	USING (npi)
	LEFT JOIN drug AS d
	ON rx.drug_name = d.drug_name
		WHERE nppes_provider_city = 'NASHVILLE'
			AND specialty_description = 'Pain Management'
			AND opioid_drug_flag = 'Y'
GROUP BY p.specialty_description, p.nppes_provider_last_org_name, rx.npi, rx.drug_name, total_claim_count
ORDER BY last_org_name ASC;


    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

-- NEED: need answer from b to answer c; 

COALESCE 
