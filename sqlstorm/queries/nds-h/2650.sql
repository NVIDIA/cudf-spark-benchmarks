WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_totalprice
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
supplier_availability AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS available_suppliers,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
high_value_customers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        c.c_nationkey,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name AS customer_name,
    p.p_name AS part_name,
    sa.available_suppliers,
    sa.total_available,
    COALESCE(hc.c_acctbal, 0) AS high_value_balance
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    supplier_availability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    high_value_customers hc ON r.c_name = hc.c_name
WHERE 
    r.rank_totalprice <= 5
    AND (l.l_discount > 0.1 OR l.l_returnflag = 'R')
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;