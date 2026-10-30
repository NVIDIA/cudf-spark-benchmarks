
WITH  supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_inner.ps_availqty)
        FROM partsupp ps_inner
        WHERE ps_inner.ps_partkey = ps.ps_partkey
    )
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' 
      AND l.l_shipdate < DATE '1998-01-01'
      AND o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
distinct_customers AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_acctbal 
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c_inner.c_acctbal) FROM customer c_inner
    )
    AND c.c_mktsegment = 'BUILDING' 
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    os.total_revenue,
    RANK() OVER (PARTITION BY sp.ps_partkey ORDER BY os.total_revenue DESC) AS revenue_rank,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM supplier_parts sp
LEFT JOIN order_summary os ON sp.ps_partkey = os.o_orderkey
LEFT JOIN distinct_customers c ON os.o_orderkey = c.c_custkey
WHERE sp.ps_supplycost < (
    SELECT AVG(ps.ps_supplycost)
    FROM partsupp ps
)
ORDER BY sp.s_name, revenue_rank;
