WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1996-01-01'
    GROUP BY l.l_orderkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.s_name AS supplier_name,
    cs.total_orders,
    cs.total_spent,
    ls.unique_parts_count,
    ls.total_revenue,
    nr.region_name
FROM SupplierStats ns
FULL OUTER JOIN CustomerOrders cs ON ns.s_suppkey = cs.c_custkey
FULL OUTER JOIN LineItemDetails ls ON cs.total_orders > 0 AND ls.l_orderkey = cs.c_custkey
JOIN NationRegion nr ON ns.s_suppkey IS NOT NULL AND nr.n_nationkey = cs.c_custkey
WHERE (ns.total_available_qty IS NULL OR ns.avg_supply_cost > 100.00)
OR (cs.total_orders > 5 AND ls.total_revenue > 5000.00)
ORDER BY supplier_name, region_name DESC;