WITH popular_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 1000
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    pp.p_name, 
    sp.s_name, 
    sp.nation_name, 
    os.o_orderkey, 
    os.o_totalprice
FROM 
    popular_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_info sp ON ps.ps_suppkey = sp.s_suppkey
JOIN 
    order_summary os ON os.o_orderkey = pp.p_partkey
WHERE 
    os.o_totalprice > 10000
ORDER BY 
    os.o_orderdate DESC, 
    pp.total_quantity DESC, 
    sp.total_cost DESC
LIMIT 10;
