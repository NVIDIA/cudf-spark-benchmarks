WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1996-01-01'
), TopOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE rn <= 10
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost, SUM(l.l_quantity) AS total_quantity
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost
), PriceVariance AS (
    SELECT tp.o_orderkey, tp.o_orderdate, tp.o_totalprice, tp.c_name, sp.ps_supplycost, (tp.o_totalprice - sp.ps_supplycost) AS price_variance
    FROM TopOrders tp
    JOIN SupplierParts sp ON tp.o_orderkey = sp.ps_partkey
)
SELECT pv.o_orderkey, pv.o_orderdate, pv.c_name, pv.o_totalprice, pv.ps_supplycost, pv.price_variance
FROM PriceVariance pv
WHERE pv.price_variance > 1000
ORDER BY pv.price_variance DESC;