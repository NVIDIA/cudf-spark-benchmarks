WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredCustomers AS (
    SELECT cs.c_custkey, cs.c_name
    FROM CustomerSummary cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
SupplierCostSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    f.c_name AS customer_name, 
    o.total_price AS order_total, 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    COALESCE(sc.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM FilteredCustomers f
JOIN OrderDetails o ON f.c_custkey = o.o_orderkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.rn = 1
JOIN SupplierCostSummary sc ON l.l_partkey = sc.p_partkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
ORDER BY total_price DESC, supplier_cost DESC
LIMIT 100;