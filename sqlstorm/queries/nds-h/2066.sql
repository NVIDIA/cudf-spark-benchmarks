
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_order_value,
        RANK() OVER (PARTITION BY os.o_custkey ORDER BY os.total_order_value DESC) AS order_rank
    FROM OrderStats os
)
SELECT 
    ss.s_name,
    rs.r_name,
    SUM(os.total_lineitems) AS total_lineitems,
    SUM(os.total_order_value) AS total_order_value,
    MAX(COALESCE(ss.total_avail_qty, 0)) AS max_avail_qty,
    AVG(COALESCE(ss.avg_supply_cost, 0)) AS avg_supply_cost,
    COUNT(oo.o_orderkey) AS total_orders
FROM SupplierStats ss
JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
JOIN RankedOrders oo ON ps.ps_partkey = oo.o_orderkey
JOIN RegionSummary rs ON ss.s_suppkey = rs.nation_count
JOIN OrderStats os ON oo.o_orderkey = os.o_orderkey
WHERE ss.total_avail_qty > 50
GROUP BY ss.s_name, rs.r_name
HAVING SUM(os.total_order_value) > 10000
ORDER BY total_order_value DESC
LIMIT 10;
