SELECT l_orderkey, SUM(l_extendedprice) AS total_extended_price
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY l_orderkey
ORDER BY total_extended_price DESC
LIMIT 10;