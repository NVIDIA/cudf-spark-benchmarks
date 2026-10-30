WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
),
best_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.total_revenue
    FROM ranked_orders ro
    WHERE ro.revenue_rank <= 10
),
supplier_part_details AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    bo.o_orderkey,
    bo.o_orderdate,
    bo.c_name,
    spd.s_name AS supplier_name,
    spd.p_brand,
    spd.p_type,
    spd.p_retailprice,
    bo.total_revenue
FROM best_orders bo
JOIN supplier_part_details spd ON bo.o_orderkey = spd.ps_partkey
ORDER BY bo.total_revenue DESC, bo.o_orderdate ASC;
