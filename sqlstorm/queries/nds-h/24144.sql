
WITH total_orders AS (
    SELECT 
        o_custkey,
        SUM(o_totalprice) AS total_spent,
        COUNT(o_orderkey) AS order_count
    FROM 
        orders
    WHERE 
        o_orderstatus IN ('O', 'F') 
    GROUP BY 
        o_custkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(t.total_spent, 0) AS total_spent,
        t.order_count
    FROM 
        customer c
    LEFT JOIN 
        total_orders t ON c.c_custkey = t.o_custkey
    WHERE 
        c.c_acctbal >= (
            SELECT AVG(c_acctbal) 
            FROM customer 
            WHERE c_acctbal IS NOT NULL
        )
),
suppliers_with_high_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_sales) FROM (
                SELECT 
                    SUM(l_extendedprice * (1 - l_discount)) AS total_sales
                FROM 
                    lineitem 
                WHERE 
                    l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
                GROUP BY 
                    l_suppkey
            ) AS avg_sales
        )
)
SELECT 
    h.c_name AS customer_name,
    s.s_name AS supplier_name,
    h.total_spent,
    s.total_sales,
    ROW_NUMBER() OVER (PARTITION BY h.c_custkey ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    high_value_customers h
FULL OUTER JOIN 
    suppliers_with_high_sales s ON h.c_custkey = s.s_suppkey
WHERE 
    (h.order_count IS NOT NULL OR s.total_sales IS NOT NULL)
AND 
    (h.total_spent > 500 OR s.total_sales < 10000)
ORDER BY 
    sales_rank, h.total_spent DESC NULLS LAST;
