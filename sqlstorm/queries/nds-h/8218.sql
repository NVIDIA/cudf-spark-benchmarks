
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ROW_NUMBER() OVER (ORDER BY ss.total_revenue DESC) AS rank
    FROM 
        SupplierSales ss
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ss.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rs.r_name AS region,
    COUNT(ts.s_suppkey) AS top_supplier_count,
    rs.nation_count,
    rs.region_revenue
FROM 
    RegionStats rs
LEFT JOIN 
    TopSuppliers ts ON rs.region_revenue > 0 AND ts.rank <= 5
GROUP BY 
    rs.r_name, rs.nation_count, rs.region_revenue
ORDER BY 
    rs.r_name ASC;
