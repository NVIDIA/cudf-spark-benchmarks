WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        o.o_orderstatus,
        o.o_orderpriority
    FROM ranked_orders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    WHERE ro.revenue_rank <= 10
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.o_orderstatus,
    t.o_orderpriority,
    s.s_name,
    s.total_supply_cost
FROM top_orders t
LEFT OUTER JOIN supplier_info s ON t.total_revenue > s.total_supply_cost
WHERE s.total_supply_cost IS NOT NULL
ORDER BY t.total_revenue DESC, s.total_supply_cost ASC;