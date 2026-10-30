WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM RankedOrders r
    WHERE r.revenue_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_quantity) AS total_ordered_quantity,
    AVG(o.total_revenue) AS avg_revenue_per_order
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN TopOrders o ON l.l_orderkey = o.o_orderkey
WHERE s.s_acctbal > 1000
GROUP BY p.p_partkey, p.p_name, s.s_name
ORDER BY avg_revenue_per_order DESC;