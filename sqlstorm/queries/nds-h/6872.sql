WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(distinct o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
        AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia'))
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.total_sales,
    rs.order_count
FROM 
    RankedSupplierSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;