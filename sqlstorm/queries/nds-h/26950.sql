WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrderAnalysis AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT sd.supplier_info, ps.p_name, ps.supplier_count, ps.avg_supply_cost,
       coa.c_name, coa.total_spent, coa.order_count
FROM SupplierDetails sd
JOIN PartStatistics ps ON ps.supplier_count > 5
JOIN CustomerOrderAnalysis coa ON coa.total_spent > 1000
WHERE sd.comment_length > 50
ORDER BY coa.total_spent DESC, ps.avg_supply_cost ASC
LIMIT 10;
