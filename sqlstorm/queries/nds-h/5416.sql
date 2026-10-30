
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, SUM(od.total_revenue) AS nation_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionRevenue AS (
    SELECT r.r_regionkey, r.r_name, SUM(nd.nation_revenue) AS total_region_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationDetails nd ON n.n_nationkey = nd.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rp.p_name, COUNT(DISTINCT sp.s_suppkey) AS supplier_count, AVG(sp.total_supply_cost) AS avg_supply_cost, rr.total_region_revenue
FROM part rp
JOIN SupplierParts sp ON rp.p_partkey = sp.s_suppkey
JOIN RegionRevenue rr ON rr.total_region_revenue > 0
GROUP BY rp.p_name, rr.total_region_revenue
ORDER BY rr.total_region_revenue DESC, supplier_count DESC;
