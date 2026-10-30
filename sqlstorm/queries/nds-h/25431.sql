
WITH part_supplier AS (
    SELECT p.p_partkey, p.p_name, s.s_name AS supplier_name, s.s_acctbal, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE LENGTH(p.p_name) > 10 AND p.p_retailprice < 100.00
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    ps.p_name AS part_name,
    ps.supplier_name,
    nd.n_name AS nation_name,
    cs.total_spent,
    CHAR_LENGTH(ps.p_name) AS name_length,
    SUBSTRING(ps.supplier_name, 1, 5) AS supplier_prefix,
    ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost
FROM part_supplier ps
JOIN nation_details nd ON ps.p_partkey = nd.n_nationkey
JOIN customer_summary cs ON cs.total_spent > 500.00
WHERE ps.s_acctbal > 1000.00
GROUP BY ps.p_name, ps.supplier_name, nd.n_name, cs.total_spent
HAVING COUNT(ps.p_partkey) > 2
ORDER BY cs.total_spent DESC, name_length ASC
LIMIT 100;
