
WITH  ordered_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
), high_spenders AS (
    SELECT oc.*, n.n_name
    FROM ordered_customers oc
    JOIN nation n ON oc.c_nationkey = n.n_nationkey
    WHERE oc.rank <= 5
), supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS total_parts, 
           SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(ps.ps_availqty) AS avg_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
), order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, MAX(l.total_revenue) AS max_revenue
    FROM orders o
    LEFT JOIN lineitem_summary l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT 
    ns.n_name,
    ss.s_name,
    hs.c_name,
    o.o_orderkey,
    o.o_totalprice,
    o.o_orderstatus,
    NULLIF(o.max_revenue, 0) AS max_order_revenue,
    CASE 
        WHEN o.o_totalprice IS NULL THEN 'No Price'
        WHEN o.o_orderstatus = 'F' AND ss.total_supply_cost > 1000 THEN 'High Priority'
        ELSE 'Standard'
    END AS order_priority
FROM high_spenders hs
JOIN supplier_summary ss ON hs.c_nationkey = ss.s_suppkey
JOIN nation ns ON hs.c_nationkey = ns.n_nationkey
LEFT JOIN order_summary o ON hs.c_custkey = o.o_orderkey
WHERE (ss.total_parts IS NULL OR ss.total_parts > 1)
  AND (hs.c_acctbal BETWEEN 500.00 AND 10000.00 OR hs.c_name LIKE '%A%')
  AND (o.o_orderstatus IS NOT NULL OR o.o_totalprice IS NOT NULL)
ORDER BY ns.n_name, ss.s_name, hs.c_name;
