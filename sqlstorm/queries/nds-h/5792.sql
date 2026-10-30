WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, p.p_name, p.p_brand, p.p_container
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
RegionWiseOrders AS (
    SELECT n.n_regionkey, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY n.n_regionkey, o.o_orderkey
),
TopRegions AS (
    SELECT r.r_name, SUM(rw.total_revenue) AS region_revenue
    FROM region r
    JOIN RegionWiseOrders rw ON r.r_regionkey = rw.n_regionkey
    GROUP BY r.r_name
    ORDER BY region_revenue DESC
    LIMIT 5
)
SELECT sp.s_suppkey, sp.s_name, sp.p_name, sp.p_brand, sp.p_container, tr.r_name, tr.region_revenue
FROM SupplierParts sp
JOIN TopRegions tr ON sp.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY tr.region_revenue DESC, sp.s_suppkey;