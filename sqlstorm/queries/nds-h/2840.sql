WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ns.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(od.total_price), 0) AS total_order_value
FROM 
    nation ns
LEFT JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    order_details od ON o.o_orderkey = od.o_orderkey
LEFT JOIN 
    supplier_summary ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            part p ON p.p_partkey = ps.ps_partkey
        WHERE 
            p.p_brand = 'Brand#27'
        ORDER BY 
            ps.ps_supplycost DESC
        LIMIT 1
    )
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_order_value DESC;