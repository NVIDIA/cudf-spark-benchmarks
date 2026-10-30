WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(co.total_orders, 0)) AS total_orders_by_nation,
        SUM(COALESCE(co.total_spent, 0)) AS total_spent_by_nation
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ns.total_orders_by_nation,
    ns.total_spent_by_nation
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationSummary ns ON n.n_nationkey = ns.n_nationkey
ORDER BY 
    r.r_name, n.n_name;
