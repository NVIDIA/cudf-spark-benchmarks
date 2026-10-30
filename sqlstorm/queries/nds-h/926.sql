WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_account_balance,
    s.total_orders,
    s.total_revenue,
    s.avg_quantity
FROM 
    NationStats ns
LEFT JOIN 
    SupplierOrderStats s ON ns.supplier_count = s.total_orders
WHERE 
    ns.total_account_balance > 1000000 OR s.total_revenue IS NOT NULL
ORDER BY 
    ns.n_name, s.total_orders DESC NULLS LAST;
