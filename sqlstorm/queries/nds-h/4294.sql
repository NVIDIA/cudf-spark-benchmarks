
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS priority_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
), 
supplier_data AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
customer_segment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    c.c_name AS customer_name,
    cs.c_mktsegment AS market_segment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    p.p_name AS part_name,
    COALESCE(AVG(sd.avg_supplycost), 0) AS avg_supply_cost,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty
FROM 
    customer_segment cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier_data sd ON l.l_partkey = sd.ps_partkey
JOIN 
    part p ON sd.ps_partkey = p.p_partkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey IS NOT NULL
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1997-01-15' AND '1997-12-31'
GROUP BY 
    c.c_name, cs.c_mktsegment, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 3
ORDER BY 
    total_revenue DESC;
