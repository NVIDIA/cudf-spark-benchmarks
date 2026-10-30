WITH SupplierSales AS (
    SELECT 
        s.s_name AS supplier_name,
        sum(ps.ps_supplycost * l.l_quantity) AS total_revenue,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_name, n.n_name
),

RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        sum(S.total_revenue) AS region_total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierSales S ON n.n_name = S.nation_name
    GROUP BY 
        r.r_name
)

SELECT 
    rs.region_name,
    rs.region_total_revenue,
    RANK() OVER (ORDER BY rs.region_total_revenue DESC) AS revenue_rank
FROM 
    RegionSales rs
ORDER BY 
    rs.region_total_revenue DESC;