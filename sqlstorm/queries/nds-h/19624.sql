SELECT p_brand, AVG(p_retailprice) AS avg_retailprice
FROM part
GROUP BY p_brand
ORDER BY avg_retailprice DESC
LIMIT 10;
