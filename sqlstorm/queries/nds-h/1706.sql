
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate >= DATE '1997-01-01' AND
        l.l_shipdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(ss.total_sales) AS region_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    COALESCE(rs.region_sales, 0) AS total_sales,
    AVG(NULLIF(ss.total_orders, 0)) AS avg_orders_per_supplier
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN 
    SupplierSales ss ON ss.total_sales > 10000 OR rs.region_sales IS NULL
GROUP BY 
    r.r_name, rs.region_sales, ss.total_orders
ORDER BY 
    total_sales DESC, r.r_name ASC;
