WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-02-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
RankedSales AS (
    SELECT 
        region_name,
        nation_name,
        region_total_sales,
        RANK() OVER (PARTITION BY region_name ORDER BY region_total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)
SELECT 
    rs.region_name,
    rs.nation_name,
    rs.region_total_sales
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank = 1
    OR rs.region_name IS NULL;