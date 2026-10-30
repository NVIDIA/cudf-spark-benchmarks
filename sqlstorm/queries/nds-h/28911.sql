
WITH RecursivePartNames AS (
    SELECT p_partkey, p_name, LENGTH(p_name) AS name_length
    FROM part
    WHERE p_name LIKE '%widget%'
    UNION ALL
    SELECT p.p_partkey, CONCAT(p.p_name, ' - ', r.r_name) AS p_name, LENGTH(CONCAT(p.p_name, ' - ', r.r_name)) AS name_length
    FROM part p
    JOIN region r ON p.p_partkey % 10 = r.r_regionkey  
    WHERE p_name LIKE '%widget%'
),
AggregatedPartCharacteristics AS (
    SELECT 
        MAX(name_length) AS max_name_length,
        MIN(name_length) AS min_name_length,
        AVG(name_length) AS avg_name_length,
        COUNT(*) AS total_parts
    FROM RecursivePartNames
)
SELECT 
    p_name,
    LENGTH(p_name) AS final_name_length,
    CASE 
        WHEN LENGTH(p_name) > (SELECT avg_name_length FROM AggregatedPartCharacteristics) THEN 'Above Average Length'
        WHEN LENGTH(p_name) < (SELECT avg_name_length FROM AggregatedPartCharacteristics) THEN 'Below Average Length'
        ELSE 'Average Length'
    END AS name_length_category
FROM RecursivePartNames
GROUP BY p_name
ORDER BY final_name_length DESC;
