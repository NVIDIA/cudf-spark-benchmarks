
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
), 
SupplierAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice,
           COALESCE(SA.total_supplycost, 0) AS total_supplycost
    FROM part p
    LEFT JOIN SupplierAggregates SA ON p.p_partkey = SA.ps_partkey
)
SELECT RD.o_orderkey, RD.o_orderdate, RD.o_totalprice, RD.c_mktsegment,
       PD.p_name, PD.p_brand, PD.total_supplycost,
       (CASE 
            WHEN PD.p_retailprice IS NULL THEN 'No Retail Price'
            ELSE CONCAT('Price: $', CAST(PD.p_retailprice AS STRING))
        END) AS retail_price_info
FROM RankedOrders RD
FULL OUTER JOIN lineitem l ON RD.o_orderkey = l.l_orderkey
JOIN ProductDetails PD ON l.l_partkey = PD.p_partkey
WHERE RD.rn <= 5
  AND (PD.total_supplycost > 1000 OR (PD.total_supplycost IS NULL AND l.l_discount > 0))
ORDER BY RD.o_orderdate DESC, PD.p_name;
