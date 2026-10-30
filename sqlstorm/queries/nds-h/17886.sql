SELECT l_linenumber, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= '1995-01-01' AND l_shipdate <= '1995-12-31'
GROUP BY l_linenumber
ORDER BY revenue DESC
LIMIT 10;