
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('O', 'H')
      AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
SupplierStats AS (
    SELECT ps.ps_partkey, s.s_name,
           SUM(ps.ps_availqty) AS TotalAvailable,
           AVG(ps.ps_supplycost) AS AvgCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
OrderDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice,
           MAX(l.l_tax) AS MaxTax
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, ro.c_name, os.TotalPrice, os.MaxTax, 
           COALESCE(st.TotalAvailable, 0) AS TotalAvailable, 
           COALESCE(st.AvgCost, 0) AS AvgCost
    FROM RankedOrders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    LEFT JOIN OrderDetails os ON o.o_orderkey = os.l_orderkey
    LEFT JOIN SupplierStats st ON st.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_retailprice > 100
          AND LENGTH(p.p_comment) > 15
    )
    WHERE ro.OrderRank <= 5
)
SELECT ho.o_orderkey, ho.o_totalprice, ho.c_name, ho.TotalPrice, ho.MaxTax,
       ROUND(ho.TotalAvailable * ho.AvgCost, 2) AS AdjustedValue,
       CASE 
           WHEN ho.TotalPrice IS NULL THEN 'No Price'
           WHEN ho.MaxTax > 0.05 THEN 'High Tax'
           ELSE 'Regular'
       END AS PriceFlag
FROM HighValueOrders ho
WHERE (ho.TotalPrice IS NOT NULL OR ho.TotalAvailable > 0)
  AND (ho.o_totalprice - ho.TotalPrice) / NULLIF(ho.o_totalprice, 0) < 0.1
ORDER BY ho.c_name, ho.o_orderkey DESC
LIMIT 100;
