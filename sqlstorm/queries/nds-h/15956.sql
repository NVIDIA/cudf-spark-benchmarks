SELECT SUM(l_extendedprice) * (1 - SUM(l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31';