WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
NationSupplierCosts AS (
    SELECT n.n_name, SUM(sc.total_cost) AS nation_total_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    GROUP BY n.n_name
),
TopNations AS (
    SELECT n.n_name, n.n_nationkey, ns.nation_total_cost
    FROM nation n
    JOIN NationSupplierCosts ns ON n.n_name = ns.n_name
    ORDER BY ns.nation_total_cost DESC
    LIMIT 5
)
SELECT tn.n_name, tn.nation_total_cost, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM TopNations tn
JOIN customer c ON c.c_nationkey = tn.n_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
GROUP BY tn.n_name, tn.nation_total_cost
ORDER BY tn.nation_total_cost DESC;
