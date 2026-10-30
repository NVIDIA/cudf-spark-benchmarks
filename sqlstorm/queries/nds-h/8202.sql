WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
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
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        r.r_name
), CustomerSales AS (
    SELECT 
        c.c_name AS customer_name,
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_name, r.r_name
)
SELECT 
    rs.region,
    rs.total_sales,
    cs.customer_name,
    cs.sales_amount
FROM 
    RegionalSales rs
LEFT JOIN 
    CustomerSales cs ON rs.region = cs.region
ORDER BY 
    rs.total_sales DESC, cs.sales_amount DESC;
