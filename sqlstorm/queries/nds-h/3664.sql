WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    ns.r_name,
    ns.n_name,
    ns.supplier_count,
    cp.c_name,
    cp.num_orders,
    cp.total_spent,
    sp.s_name,
    sp.total_cost,
    sp.order_count
FROM NationRegion ns
LEFT JOIN CustomerOrders cp ON ns.n_name = cp.c_name
LEFT JOIN SupplierPerformance sp ON ns.supplier_count > 0 AND sp.rn = 1
WHERE 
    (cp.total_spent IS NULL OR cp.total_spent > 1000)
    AND (sp.total_cost IS NOT NULL AND sp.total_cost > 5000)
ORDER BY ns.r_name, ns.n_name, cp.total_spent DESC;
