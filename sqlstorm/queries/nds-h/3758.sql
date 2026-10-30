WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.n_name AS nation_name,
    n.region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    COALESCE(SUM(su.total_supply_cost), 0) AS total_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_quantity
FROM Nations n
LEFT JOIN RankedOrders ro ON n.n_nationkey = ro.c_nationkey AND ro.rn <= 5
LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN SupplierCosts su ON l.l_partkey = su.ps_partkey
WHERE (n.n_name IS NOT NULL AND n.region_name IS NOT NULL)
GROUP BY n.n_name, n.region_name
ORDER BY total_revenue DESC, total_orders DESC;
