WITH supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
line_items_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cp.c_name AS customer_name,
    cp.o_orderkey AS order_id,
    cp.o_orderdate AS order_date,
    lp.total_revenue AS total_order_revenue,
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.p_brand AS part_brand,
    sp.p_type AS part_type,
    sp.ps_availqty AS available_quantity,
    sp.ps_supplycost AS supply_cost
FROM 
    customer_orders cp
JOIN 
    line_items_summary lp ON cp.o_orderkey = lp.l_orderkey
JOIN 
    supplier_parts sp ON lp.l_orderkey = sp.s_suppkey
WHERE 
    cp.o_orderdate >= DATE '1997-01-01' AND 
    lp.total_revenue > 100.00
ORDER BY 
    cp.o_orderdate DESC, 
    lp.total_revenue DESC;