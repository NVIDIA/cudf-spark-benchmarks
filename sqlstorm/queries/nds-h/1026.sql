WITH supplier_sales AS (
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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_consumption AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 100 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier_name,
    cc.c_name AS customer_name,
    s.total_sales AS supplier_total_sales,
    cc.total_spent AS customer_total_spent,
    (CASE 
        WHEN s.total_sales IS NULL THEN 0 
        WHEN cc.total_spent IS NULL THEN 0 
        ELSE (s.total_sales - cc.total_spent) 
    END) AS sales_difference,
    (ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.total_sales DESC) * 0.01) AS sales_rank
FROM 
    supplier_sales s
FULL OUTER JOIN 
    customer_consumption cc ON s.s_suppkey = cc.c_custkey
WHERE 
    (cc.order_count > 10 OR s.order_count > 5)
ORDER BY 
    sales_difference DESC NULLS LAST;