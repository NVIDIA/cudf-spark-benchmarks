WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'  
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    ss.s_name,
    ss.total_supply_value,
    ss.total_parts
FROM 
    customer_summary cs
JOIN 
    lineitem l ON cs.c_custkey = l.l_orderkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier_summary ss ON l.l_suppkey = ss.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    cs.total_spent DESC, ss.total_supply_value DESC
LIMIT 10;