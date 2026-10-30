WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_order_value) AS total_spent,
        COUNT(od.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        order_details od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cos.total_spent,
        cos.order_count,
        ROW_NUMBER() OVER (ORDER BY cos.total_spent DESC) AS rank
    FROM 
        customer_order_summary cos
    JOIN 
        customer c ON cos.c_custkey = c.c_custkey
    WHERE 
        cos.total_spent IS NOT NULL
)

SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    tc.order_count,
    ss.s_name AS top_supplier,
    ss.total_supply_value
FROM 
    top_customers tc
LEFT JOIN 
    supplier_summary ss ON ss.total_supply_value = (SELECT MAX(total_supply_value) FROM supplier_summary)
WHERE 
    tc.rank <= 10  
ORDER BY 
    tc.total_spent DESC;