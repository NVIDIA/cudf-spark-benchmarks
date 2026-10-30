WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
    WHERE 
        s.total_sales > 0
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    ts.r_name,
    ts.supplier_count,
    ts.region_total_sales,
    COALESCE(avg_sales.avg_sales, 0) AS avg_sales_per_supplier
FROM 
    TopSuppliers ts
LEFT JOIN (
    SELECT 
        r.r_name,
        AVG(total_sales) AS avg_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_name
) avg_sales ON ts.r_name = avg_sales.r_name
ORDER BY 
    ts.region_total_sales DESC, ts.r_name;