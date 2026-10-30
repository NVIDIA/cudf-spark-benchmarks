
WITH  order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_lines,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate > '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_sales,
    os.total_lines,
    c.c_name AS customer_name,
    sp.s_name AS supplier_name,
    CASE 
        WHEN os.total_sales > 5000 THEN 'High Value Order'
        ELSE 'Regular Order' 
    END AS order_type,
    sp.total_supply_cost
FROM 
    order_summary os
LEFT JOIN 
    high_value_customers c ON os.total_sales > c.customer_total
JOIN 
    supplier_performance sp ON os.o_orderkey = sp.s_suppkey
ORDER BY 
    os.o_orderdate DESC, os.total_sales DESC
LIMIT 100;
