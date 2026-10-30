WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
top_revenue_orders AS (
    SELECT 
        ro.o_orderkey, 
        ro.revenue,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM ranked_orders ro
    JOIN customer c ON ro.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ro.rank <= 10
),
supplier_parts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    tro.o_orderkey,
    tro.revenue,
    tro.c_name,
    tro.nation_name,
    tro.region_name,
    sp.total_supply_cost
FROM top_revenue_orders tro
JOIN supplier_parts sp ON tro.o_orderkey = sp.s_suppkey
ORDER BY tro.revenue DESC, sp.total_supply_cost ASC;
