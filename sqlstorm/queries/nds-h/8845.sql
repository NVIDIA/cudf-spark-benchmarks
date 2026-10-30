WITH 
    regional_sales AS (
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
            l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
        GROUP BY 
            r.r_name
    ),
    customer_sales AS (
        SELECT 
            c.c_name AS customer_name,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
        FROM 
            customer c
        JOIN 
            orders o ON c.c_custkey = o.o_custkey
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
        GROUP BY 
            c.c_name
    )
SELECT 
    rs.region,
    COUNT(DISTINCT cs.customer_name) AS unique_customers,
    SUM(rs.total_sales) AS total_sales_per_region,
    AVG(cs.customer_total) AS avg_sales_per_customer
FROM 
    regional_sales rs
JOIN 
    customer_sales cs ON rs.region IN (
        SELECT r.r_name
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
        GROUP BY 
            r.r_name
    )
GROUP BY 
    rs.region
ORDER BY 
    total_sales_per_region DESC;