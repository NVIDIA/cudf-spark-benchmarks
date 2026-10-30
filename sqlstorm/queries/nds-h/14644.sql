WITH SupplierRevenue AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), NationRevenue AS (
    SELECT 
        n.n_name, 
        SUM(sr.total_revenue) AS nation_revenue
    FROM 
        nation n
    JOIN 
        SupplierRevenue sr ON n.n_nationkey = sr.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name, 
    n.nation_revenue
FROM 
    NationRevenue n
ORDER BY 
    n.nation_revenue DESC
LIMIT 10;
