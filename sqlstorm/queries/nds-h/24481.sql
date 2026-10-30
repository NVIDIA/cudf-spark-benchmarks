WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
PartPriceDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
                THEN 'High Value' ELSE 'Low Value' END AS customer_type
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT COALESCE(n.n_name, 'Unknown Region') AS nation_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(l.l_discount * l.l_extendedprice) AS avg_discounted_price,
       SUM(p.p_retailprice) AS total_part_price,
       MAX(CASE WHEN rs.rank = 1 THEN rs.s_name END) AS top_supplier,
       COUNT(hc.c_custkey) FILTER (WHERE hc.customer_type = 'High Value') AS high_value_count
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
FULL OUTER JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
LEFT JOIN HighValueCustomers hc ON c.c_custkey = hc.c_custkey
LEFT JOIN PartPriceDetails p ON l.l_partkey = p.p_partkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
  AND (c.c_acctbal IS NULL OR c.c_acctbal > 0)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_orders DESC, total_part_price ASC;