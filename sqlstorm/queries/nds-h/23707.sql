
WITH RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER(PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal, n.n_name
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost, p.p_brand
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_brand
),
FilteredSuppliers AS (
    SELECT s.*, ROW_NUMBER() OVER(PARTITION BY s.p_brand ORDER BY avg_supply_cost ASC) AS brand_rank
    FROM SupplierPartDetails s
    WHERE s.total_available > 10
),
RecentCustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.nation_name, 
           o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM CustomerDetails c
    JOIN RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE o.rn = 1 AND c.total_spent > 1000
)
SELECT DISTINCT r.c_custkey, r.c_name, r.c_acctbal, r.nation_name, r.o_orderkey, 
                r.o_orderdate, r.o_totalprice, s.s_name AS supplier_name, 
       CASE 
           WHEN r.o_totalprice > 500 THEN 'High'
           WHEN r.o_totalprice BETWEEN 300 AND 500 THEN 'Medium'
           ELSE 'Low'
       END AS price_category
FROM RecentCustomerOrders r
LEFT JOIN FilteredSuppliers s ON r.nation_name = s.p_brand
WHERE r.c_acctbal IS NOT NULL AND r.c_acctbal >= 100
AND (r.o_orderdate > '1997-01-01' OR r.o_orderdate IS NULL)
UNION ALL
SELECT c.c_custkey, c.c_name, c.c_acctbal, c.nation_name, 
       NULL AS o_orderkey, NULL AS o_orderdate, NULL AS o_totalprice, 
       NULL AS supplier_name, 'Not Applicable' AS price_category
FROM CustomerDetails c
WHERE NOT EXISTS (SELECT 1 FROM RecentCustomerOrders r WHERE r.c_custkey = c.c_custkey)
ORDER BY o_orderdate DESC NULLS LAST;
