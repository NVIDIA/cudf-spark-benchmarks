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
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
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
),
CustomerRegionSales AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, n.n_name
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.total_sales,
    rs.order_count,
    crs.total_spent AS customer_sales,
    COALESCE(crs.nation_name, 'Unknown') AS nation_name,
    CASE 
        WHEN rs.order_count > 0 THEN ROUND(rs.total_sales / rs.order_count, 2) 
        ELSE NULL 
    END AS avg_sales_per_order
FROM 
    RankedSuppliers rs
LEFT JOIN 
    CustomerRegionSales crs ON rs.s_suppkey = crs.c_custkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;