WITH  high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_retailprice > 50
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-09-30'
    GROUP BY o.o_orderkey
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
final_report AS (
    SELECT 
        h.o_orderkey,
        h.o_totalprice,
        s.region_name,
        d.net_revenue,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost
    FROM high_value_orders h
    LEFT JOIN supplier_info s ON h.o_orderkey = s.s_suppkey
    LEFT JOIN order_details d ON h.o_orderkey = d.o_orderkey
    WHERE h.rnk <= 10
)
SELECT 
    order_rank,
    region_name,
    SUM(net_revenue) AS total_net_revenue,
    SUM(total_supply_cost) AS total_cost
FROM final_report
JOIN ranked_orders r ON final_report.o_orderkey = r.o_orderkey
GROUP BY order_rank, region_name
ORDER BY order_rank, region_name;