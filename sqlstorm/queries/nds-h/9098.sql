WITH supplier_stats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_account_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
nation_stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        ss.total_suppliers,
        ss.total_account_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier_stats ss ON n.n_nationkey = ss.s_nationkey
),
order_summary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    ns.n_name,
    ns.region_name,
    ns.total_suppliers,
    ns.total_account_balance,
    os.total_orders,
    os.total_revenue
FROM 
    nation_stats ns
LEFT JOIN 
    order_summary os ON ns.n_nationkey = os.o_custkey
WHERE 
    ns.total_suppliers > 5 
    AND os.total_revenue > 10000
ORDER BY 
    ns.total_account_balance DESC, 
    os.total_orders DESC
LIMIT 10;
