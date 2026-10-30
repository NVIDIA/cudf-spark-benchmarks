WITH  SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           NTILE(4) OVER (ORDER BY SUM(o.o_totalprice) DESC) AS quartile
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COALESCE(cr.total_spent, 0) AS total_spent_by_customer,
    sr.rank AS supplier_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierRank sr ON sr.s_suppkey = ps.ps_suppkey
LEFT JOIN (SELECT DISTINCT c.c_custkey, cr.total_spent
            FROM CustomerRank cr
            JOIN customer c ON cr.c_custkey = c.c_custkey
            WHERE cr.quartile = 1) cr ON cr.total_spent > 10000
WHERE p.p_size > 10 
GROUP BY p.p_partkey, p.p_name, p.p_brand, cr.total_spent, sr.rank
HAVING AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY total_spent_by_customer DESC NULLS LAST;