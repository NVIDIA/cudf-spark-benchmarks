WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
combined_orders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_suppkey) FILTER (WHERE l.l_returnflag = 'R') AS return_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, c.c_name
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name AS nation_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(co.revenue, 0) AS revenue,
    co.total_quantity,
    COUNT(z.o_orderkey) AS processed_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
LEFT JOIN 
    orders z ON z.o_orderkey = l.l_orderkey 
LEFT JOIN 
    customer c ON z.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
FULL OUTER JOIN 
    combined_orders co ON z.o_orderkey = co.o_orderkey
WHERE 
    (p.p_size IS NULL OR p.p_size > 10)
    AND (co.revenue IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
GROUP BY 
    p.p_name, r.r_name, n.n_name, ss.total_supply_cost, co.revenue, co.total_quantity
HAVING 
    SUM(CASE WHEN l.l_tax > 0 THEN l.l_tax END) IS NULL
ORDER BY 
    total_supply_cost DESC NULLS FIRST;
