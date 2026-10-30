WITH RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    ts.region_name,
    ts.nation_name,
    COUNT(*) AS supplier_count,
    SUM(ts.total_sales) AS total_sales
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    ts.region_name, total_sales DESC;