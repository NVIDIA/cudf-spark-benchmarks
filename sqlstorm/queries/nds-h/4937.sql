WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_available_quantity DESC) AS rank
    FROM SupplierStats
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.revenue) AS total_revenue
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(ts.total_available_quantity, 0) AS available_quantity,
    COALESCE(ts.average_supply_cost, 0) AS avg_supply_cost,
    cr.total_revenue,
    CASE 
        WHEN cr.total_revenue IS NULL THEN 'No Orders'
        WHEN cr.total_revenue > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM customer cs
LEFT JOIN TopSuppliers ts ON cs.c_custkey = ts.s_suppkey
LEFT JOIN CustomerRevenue cr ON cs.c_custkey = cr.c_custkey
WHERE cs.c_acctbal > 0
ORDER BY cs.c_name, cr.total_revenue DESC;