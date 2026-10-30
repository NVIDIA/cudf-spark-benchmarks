WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-01-01' AND o.o_orderdate < DATE '1999-01-01'
    GROUP BY 
        r.r_name, n.n_name
),
TopRegions AS (
    SELECT 
        region_name, 
        SUM(total_sales) AS total_region_sales
    FROM 
        RegionalSales
    GROUP BY 
        region_name
    ORDER BY 
        total_region_sales DESC
    LIMIT 5
)
SELECT 
    tr.region_name,
    tr.total_region_sales,
    COUNT(*) AS number_of_nations
FROM 
    TopRegions tr
JOIN 
    RegionalSales rs ON tr.region_name = rs.region_name
GROUP BY 
    tr.region_name, tr.total_region_sales
ORDER BY 
    tr.total_region_sales DESC;
