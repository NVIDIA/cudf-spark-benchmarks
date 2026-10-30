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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)

SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    MAX(rs.total_sales) AS max_sales,
    AVG(rs.total_sales) AS avg_sales,
    SUM(COALESCE(rs.order_count, 0)) AS total_orders
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    MAX(rs.total_sales) > 10000
ORDER BY 
    region_name, nation_name;