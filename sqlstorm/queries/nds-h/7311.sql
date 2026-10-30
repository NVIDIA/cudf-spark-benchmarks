WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
lineitem_summary AS (
    SELECT l.l_orderkey, COUNT(*) AS total_lines, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT
    sd.s_name AS supplier_name,
    sd.nation AS supplier_nation,
    COALESCE(SUM(lo.total_sales), 0) AS total_sales,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    AVG(sd.total_cost) AS avg_supplier_cost
FROM supplier_details sd
LEFT JOIN lineitem_summary lo ON sd.s_suppkey = lo.l_orderkey
LEFT JOIN customer_orders co ON lo.l_orderkey = co.o_orderkey
WHERE sd.s_acctbal > 5000
GROUP BY sd.s_suppkey, sd.s_name, sd.nation
ORDER BY total_sales DESC, avg_supplier_cost ASC
LIMIT 10;
