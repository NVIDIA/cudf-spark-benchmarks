WITH  supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand
),
ranked_suppliers AS (
    SELECT s.*, RANK() OVER (PARTITION BY p_name ORDER BY total_available DESC) AS rank
    FROM supplier_parts s
)
SELECT r.r_name, n.n_name, SUM(o.o_totalprice) AS total_order_value, COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers, COUNT(DISTINCT l.l_orderkey) AS total_lineitems,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE s.s_suppkey IN (SELECT s_suppkey FROM ranked_suppliers WHERE rank = 1)
GROUP BY r.r_name, n.n_name
ORDER BY total_order_value DESC, total_orders DESC;
