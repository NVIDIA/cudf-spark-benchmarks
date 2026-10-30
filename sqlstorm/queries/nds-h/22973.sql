WITH  highest_transactions AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(total) FROM (SELECT SUM(o_totalprice) AS total FROM orders GROUP BY o_custkey) AS avg_total)
), regional_suppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
filtered_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'F'
    GROUP BY l.l_orderkey, l.l_partkey
),
but_not_care AS (
    SELECT n.n_name, SUM(l.total_price) AS total_lineitem_revenue
    FROM filtered_lineitems l
    JOIN highest_transactions ht ON l.l_orderkey = ht.c_custkey
    JOIN nation n ON ht.total_spent > (SELECT COUNT(*) FROM customer) 
    WHERE l.total_price IS NOT NULL
    GROUP BY n.n_name
)
SELECT r.r_name AS region, SUM(b.total_lineitem_revenue) AS overall_revenue
FROM region r
LEFT JOIN but_not_care b ON r.r_name = b.n_name
GROUP BY r.r_name
HAVING SUM(b.total_lineitem_revenue) IS NULL OR COUNT(DISTINCT r.r_name) > 1
ORDER BY overall_revenue DESC NULLS LAST;
