WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS supplier_nation, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM orders o
    GROUP BY o.o_custkey
    HAVING COUNT(o.o_orderkey) > 5
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown Balance'
               WHEN c.c_acctbal < 500 THEN 'Low Balance'
               ELSE 'Sufficient Balance' 
           END AS balance_status
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
DetailedSupplierCosts AS (
    SELECT sd.s_suppkey, sd.s_name, sd.total_cost,
           ROW_NUMBER() OVER (ORDER BY sd.total_cost DESC) AS supplier_rank
    FROM SupplierDetails sd
    WHERE sd.total_cost > 10000
)
SELECT 
    cd.c_custkey, 
    cd.c_name, 
    os.order_count, 
    os.total_spent,
    dsc.supplier_rank, 
    dsc.s_name AS top_supplier, 
    dsc.total_cost AS supplier_total_cost, 
    cd.balance_status
FROM CustomerDetails cd
LEFT JOIN OrderSummary os ON cd.c_custkey = os.o_custkey
LEFT JOIN DetailedSupplierCosts dsc ON dsc.supplier_rank = 1
WHERE cd.c_nationkey IN (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_name LIKE 'A%'
)
ORDER BY cd.c_custkey, os.total_spent DESC;
