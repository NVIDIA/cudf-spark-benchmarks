WITH total_order_value AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
big_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        t.order_value
    FROM 
        total_order_value t
    JOIN 
        orders o ON t.o_orderkey = o.o_orderkey
    WHERE 
        t.order_value > 50000
)
SELECT
    n.n_name AS nation_name,
    SUM(COALESCE(ss.total_supply_value, 0)) AS total_supplier_value,
    COUNT(DISTINCT bo.o_orderkey) AS big_order_count,
    EXTRACT(YEAR FROM bo.o_orderdate) AS order_year
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_stats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    big_orders bo ON s.s_suppkey = bo.o_orderkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name, EXTRACT(YEAR FROM bo.o_orderdate)
HAVING 
    SUM(COALESCE(ss.total_supply_value, 0)) > 100000
ORDER BY 
    order_year DESC, nation_name;
