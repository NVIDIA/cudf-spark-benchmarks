WITH  SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, n.n_name AS supplier_nation
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
      AND ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500)
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS number_of_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    sh.supplier_nation,
    COUNT(DISTINCT sh.s_suppkey) AS number_of_suppliers,
    SUM(oss.total_spent) AS total_customer_spending,
    SUM(lis.number_of_items) AS total_items_ordered,
    SUM(lis.total_value) AS total_order_value
FROM SupplierHierarchy sh
JOIN OrderSummary oss ON sh.supplier_nation = oss.c_name
JOIN LineItemStats lis ON oss.c_custkey = lis.l_orderkey
GROUP BY sh.supplier_nation
ORDER BY total_order_value DESC
LIMIT 10;