WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1993-01-01' AND o.o_orderdate < DATE '1994-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_shipped,
    SUM(CASE WHEN p.p_container = 'SM CASE' THEN l.l_quantity ELSE 0 END) AS sm_case_total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    top_orders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.total_revenue
ORDER BY 
    t.total_revenue DESC;
