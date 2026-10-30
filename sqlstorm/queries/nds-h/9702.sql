WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
),
top_customer_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.o_totalprice
    FROM 
        ranked_orders ro
    WHERE 
        ro.rn <= 5
),
product_sales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
final_report AS (
    SELECT 
        tco.o_orderkey,
        tco.o_orderdate,
        tco.c_name,
        tco.o_totalprice,
        ps.total_sales
    FROM 
        top_customer_orders tco
    LEFT JOIN 
        product_sales ps ON tco.o_orderkey = ps.l_orderkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.c_name,
    fr.o_totalprice,
    COALESCE(fr.total_sales, 0) AS total_sales
FROM 
    final_report fr
WHERE 
    fr.total_sales > 5000
ORDER BY 
    fr.o_totalprice DESC, fr.o_orderdate ASC;