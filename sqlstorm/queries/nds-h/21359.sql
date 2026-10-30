WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_suppkey,
        rs.s_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE 
        rs.rank_acctbal <= 3
),
SalesInfo AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        COUNT(l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierSales AS (
    SELECT 
        ts.r_name,
        si.total_sale,
        si.total_lines,
        COUNT(si.o_orderkey) AS orders_count
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        SalesInfo si ON l.l_orderkey = si.o_orderkey
    GROUP BY 
        ts.r_name, si.total_sale, si.total_lines
)
SELECT 
    s.r_name,
    SUM(s.total_sale) AS total_sales,
    COUNT(DISTINCT s.orders_count) AS distinct_orders,
    AVG(CASE WHEN s.total_lines IS NULL THEN 0 ELSE s.total_lines END) AS avg_lines_per_order,
    MAX(s.total_sale) AS max_sale,
    CASE 
        WHEN SUM(s.total_sale) > 10000 THEN 'High Sales'
        WHEN SUM(s.total_sale) BETWEEN 5000 AND 10000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    SupplierSales s
GROUP BY 
    s.r_name
HAVING 
    COUNT(s.orders_count) > 5
ORDER BY 
    total_sales DESC, sales_category ASC;