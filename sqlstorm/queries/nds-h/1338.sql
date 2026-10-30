WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_nationkey
),
NationSummary AS (
    SELECT 
        n.n_name,
        COALESCE(ss.supplier_count, 0) AS supplier_count,
        COALESCE(co.order_count, 0) AS order_count,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(co.total_order_value, 0) AS total_order_value
    FROM nation n
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_nationkey
)
SELECT 
    n.n_name,
    n.supplier_count,
    n.order_count,
    n.total_supply_cost,
    n.total_order_value,
    CASE 
        WHEN n.order_count = 0 THEN NULL
        ELSE n.total_order_value / NULLIF(n.order_count, 0)
    END AS avg_order_value,
    ROW_NUMBER() OVER (ORDER BY n.total_order_value DESC) AS rank_by_order_value
FROM NationSummary n
WHERE n.total_supply_cost > 0
ORDER BY n.total_order_value DESC
LIMIT 10;