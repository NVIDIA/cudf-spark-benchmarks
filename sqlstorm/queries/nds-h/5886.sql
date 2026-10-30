
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        p.p_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND (l.l_discount > 0.05 AND l.l_discount < 0.15)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(ro.o_totalprice) AS avg_order_value,
    MAX(ro.o_totalprice) AS max_order_value,
    MIN(ro.o_totalprice) AS min_order_value
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.rank_order <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
