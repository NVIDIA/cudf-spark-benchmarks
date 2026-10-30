WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= '1995-01-01' 
        AND o.o_orderdate < '1997-01-01'
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p 
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
customer_order_counts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    ns.n_name,
    s.s_name,
    COUNT(DISTINCT lo.l_orderkey) AS total_lines,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COALESCE(coc.order_count, 0) AS total_orders,
    CASE 
        WHEN total_supply_cost > 10000 THEN 'High supplier cost'
        ELSE 'Regular supplier cost' 
    END AS supply_cost_category
FROM 
    region r 
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem lo ON s.s_suppkey = lo.l_suppkey
LEFT JOIN 
    customer_order_counts coc ON coc.c_custkey = lo.l_orderkey
LEFT JOIN 
    supplier_stats ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    EXISTS (SELECT 1 FROM high_value_parts hvp WHERE hvp.p_partkey = lo.l_partkey)
GROUP BY 
    r.r_name, ns.n_name, s.s_name, ss.total_supply_cost, coc.order_count
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;