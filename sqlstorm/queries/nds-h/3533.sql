WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND
        o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        total_sales,
        sales_rank
    FROM 
        SupplierSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    n.n_name AS nation,
    rs.s_name,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No sales'
        WHEN rs.total_sales > 1000000 THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    RankedSuppliers rs
LEFT JOIN 
    nation n ON rs.s_suppkey = n.n_nationkey
ORDER BY 
    nation, rs.total_sales DESC;