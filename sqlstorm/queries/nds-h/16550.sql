SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate <= '1997-12-31'
GROUP BY l_orderkey
ORDER BY total_price DESC
LIMIT 10;