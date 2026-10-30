SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;
