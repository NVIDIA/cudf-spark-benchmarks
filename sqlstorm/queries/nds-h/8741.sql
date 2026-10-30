
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierRegionData AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS supplier_nation, 
           r.r_name AS supplier_region, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, r.r_name
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, 
       sr.supplier_region, sr.total_supplycost,
       r.price_rank
FROM RankedOrders r
JOIN lineitem l ON r.o_orderkey = l.l_orderkey
JOIN SupplierRegionData sr ON l.l_suppkey = sr.s_suppkey
WHERE r.price_rank <= 5 AND sr.total_supplycost > 10000
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;
