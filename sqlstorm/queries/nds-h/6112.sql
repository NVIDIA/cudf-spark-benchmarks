WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(sos.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    JOIN 
        SupplierOrderSummary sos ON n.n_nationkey = sos.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region,
    SUM(nr.total_nation_revenue) AS total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationRevenue nr ON n.n_nationkey = nr.n_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
