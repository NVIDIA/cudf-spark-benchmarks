WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(rs.total_price) AS avg_order_value,
    SUM(su.total_supply_cost) AS total_supply_cost
FROM 
    ranked_orders rs
LEFT JOIN 
    orders o ON rs.o_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier_summary su ON c.c_nationkey = su.s_nationkey
LEFT JOIN 
    nation_region n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= '1997-01-01'
    AND o.o_orderstatus = 'O'
    AND (su.total_supply_cost IS NOT NULL OR rs.total_price > 1000)
GROUP BY 
    n.r_name
ORDER BY 
    total_supply_cost DESC, avg_order_value ASC;