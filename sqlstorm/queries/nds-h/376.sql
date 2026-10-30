WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)

SELECT 
    nr.n_name AS nation_name,
    nr.region_name,
    COALESCE(sr.total_revenue, 0) AS supplier_revenue,
    nr.supplier_count,
    CASE 
        WHEN sr.total_revenue IS NOT NULL AND nr.supplier_count > 0 THEN 
            sr.total_revenue / nr.supplier_count 
        ELSE 
            NULL 
    END AS avg_revenue_per_supplier
FROM 
    NationRegion nr
LEFT JOIN 
    SupplierRevenue sr ON nr.n_nationkey = sr.s_suppkey
WHERE 
    nr.supplier_count > 0 OR sr.total_revenue IS NOT NULL
ORDER BY 
    nr.region_name, avg_revenue_per_supplier DESC;
