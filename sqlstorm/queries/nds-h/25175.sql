WITH NameParts AS (
    SELECT SUBSTRING(p_name, 1, 10) AS short_name,
           UPPER(p_brand) AS upper_brand,
           LENGTH(p_name) AS name_length,
           p_retailprice
    FROM part
),
SupplierStats AS (
    SELECT s.s_name,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
CombinedData AS (
    SELECT np.short_name,
           np.upper_brand,
           np.name_length,
           ss.s_name,
           ss.total_parts,
           ss.total_supplycost
    FROM NameParts np
    JOIN SupplierStats ss ON np.p_retailprice > ss.total_supplycost
)
SELECT short_name,
       upper_brand,
       name_length,
       s_name,
       total_parts,
       total_supplycost
FROM CombinedData
WHERE name_length > 5 AND total_parts > 10
ORDER BY total_supplycost DESC, name_length ASC
LIMIT 50;
