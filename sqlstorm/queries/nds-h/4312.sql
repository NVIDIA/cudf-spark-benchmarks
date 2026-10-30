
WITH supplier_stats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS average_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_region AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT
    ss.s_suppkey,
    ss.s_name,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    ss.total_supply_cost,
    ss.num_parts,
    lr.net_revenue,
    lr.average_quantity,
    nr.region_name,
    nr.nation_name
FROM supplier_stats ss
JOIN customer_orders cs ON ss.s_suppkey = cs.c_custkey
LEFT JOIN lineitem_summary lr ON cs.order_count > 0 AND lr.l_orderkey = cs.c_custkey
JOIN nation_region nr ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size > 20
    )
)
ORDER BY total_spent_by_customer DESC, ss.total_supply_cost ASC;
