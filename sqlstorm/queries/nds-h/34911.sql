WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           customer.c_name, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    JOIN customer ON o.o_custkey = customer.c_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
), PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), RegionSupplier AS (
    SELECT s.s_suppkey, r.r_name, 
           COUNT(DISTINCT s.s_nationkey) AS nation_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, r.r_name
)
SELECT 
    o.order_rank, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    psi.total_available, 
    psi.average_supply_cost, 
    CASE 
        WHEN rsi.nation_count IS NULL THEN 'No Suppliers'
        ELSE rsi.r_name 
    END AS supplier_region
FROM OrderHierarchy o
LEFT JOIN PartSupplierInfo psi ON o.o_orderkey = psi.ps_partkey
LEFT JOIN RegionSupplier rsi ON psi.ps_suppkey = rsi.s_suppkey
WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < cast('1998-10-01' as date) - INTERVAL '1 year')
OR psi.total_available IS NULL
ORDER BY o.o_orderdate DESC, supplier_region;