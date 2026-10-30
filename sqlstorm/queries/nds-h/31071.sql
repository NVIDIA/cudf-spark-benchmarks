
WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
), 

CustomerRank AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name AS region_name,
    r.total_sales AS region_total_sales,
    cr.c_name AS customer_name,
    cr.total_spent AS customer_total_spent
FROM 
    RegionalSales r
FULL OUTER JOIN CustomerRank cr ON r.sales_rank = 1 AND cr.customer_rank <= 10
WHERE 
    (r.total_sales IS NOT NULL OR cr.total_spent IS NOT NULL)
ORDER BY 
    r.total_sales DESC, 
    cr.total_spent DESC;
