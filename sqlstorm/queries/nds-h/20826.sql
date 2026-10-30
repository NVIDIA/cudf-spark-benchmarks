WITH  OrderChain AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        l.l_orderkey, 
        c.c_name, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    ns.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    COUNT(DISTINCT oc.o_orderkey) AS order_count,
    MAX(oc.o_orderdate) AS last_order_date,
    CASE 
        WHEN SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) > 10000 THEN 'High Revenue'
        WHEN SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    partsupp ps
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    OrderChain oc ON l.l_orderkey = oc.o_orderkey
WHERE 
    r.r_name IS NOT NULL 
    AND (oc.order_rank IS NULL OR oc.order_rank = 1)
GROUP BY 
    ns.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
