WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
SupplierMetrics AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(cm.total_orders, 0) AS customer_order_count,
    sm.total_avail_qty,
    sm.avg_supply_cost,
    CASE 
        WHEN sm.avg_supply_cost IS NULL THEN 'No Supplier'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM RankedOrders r
LEFT JOIN CustomerOrders cm ON r.o_orderkey = cm.total_orders
LEFT JOIN SupplierMetrics sm ON sm.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'Widget%')
WHERE r.rnk = 1
AND r.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < r.o_orderdate)
UNION ALL
SELECT 
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    NULL AS o_totalprice,
    COUNT(DISTINCT n.n_nationkey) AS unique_nations,
    NULL AS total_avail_qty,
    NULL AS avg_supply_cost,
    'Nation Count' AS supplier_status
FROM nation n
WHERE n.n_regionkey NOT IN (
    SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%West%'
);
