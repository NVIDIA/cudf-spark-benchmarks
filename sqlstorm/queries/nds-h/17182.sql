SELECT p.p_name, SUM(l.l_extendedprice) AS Total_Sales
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p.p_name
ORDER BY Total_Sales DESC
LIMIT 10;
