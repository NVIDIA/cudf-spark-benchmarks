
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.revenue
    FROM 
        ranked_orders r
    WHERE 
        r.order_rank <= 10
),
supplier_parts AS (
    SELECT 
        p.p_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, ps.ps_suppkey, s.s_name
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    sp.s_name, 
    sp.total_avail_qty, 
    sp.avg_supply_cost, 
    o.revenue
FROM 
    top_orders o
JOIN 
    supplier_parts sp ON o.o_orderkey = sp.ps_suppkey
ORDER BY 
    o.revenue DESC, o.o_orderdate ASC;
