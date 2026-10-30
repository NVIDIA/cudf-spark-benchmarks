WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
high_value_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue,
        s.s_name,
        s.s_address
    FROM 
        ranked_orders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    h. o_orderkey,
    h.o_orderdate,
    h.total_revenue,
    COUNT(s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    high_value_orders h
JOIN 
    supplier s ON h.s_name = s.s_name
GROUP BY 
    h.o_orderkey, h.o_orderdate, h.total_revenue
ORDER BY 
    h.total_revenue DESC;
