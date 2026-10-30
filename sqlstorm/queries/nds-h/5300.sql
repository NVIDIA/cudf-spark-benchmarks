WITH regional_summary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(c.c_acctbal) AS average_customer_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderstatus 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
final_summary AS (
    SELECT 
        rs.region_name,
        os.o_orderkey,
        os.total_price,
        os.o_orderdate,
        os.o_orderstatus,
        rs.total_supply_cost,
        rs.supplier_count,
        rs.average_customer_balance
    FROM regional_summary rs
    JOIN order_summary os ON os.total_price > rs.total_supply_cost / rs.supplier_count
)
SELECT 
    region_name,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(total_price) AS total_revenue,
    AVG(average_customer_balance) AS avg_customer_balance,
    MAX(total_supply_cost) AS max_supply_cost
FROM final_summary
GROUP BY region_name
ORDER BY total_revenue DESC;
