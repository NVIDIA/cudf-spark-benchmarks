
WITH SupplierTotalCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
SalesRanked AS (
    SELECT c.c_custkey, c.c_name, c.total_spent, RANK() OVER (ORDER BY c.total_spent DESC) AS sales_rank
    FROM CustomerOrderDetails c
),
RegionalSupplierCosts AS (
    SELECT n.n_regionkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(stc.total_cost) AS regional_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierTotalCosts stc ON s.s_suppkey = stc.s_suppkey
    GROUP BY n.n_regionkey, n.n_name
)
SELECT r.n_name AS region_name, r.supplier_count, r.regional_cost, sr.c_name AS top_customer, sr.total_spent
FROM RegionalSupplierCosts r
LEFT JOIN SalesRanked sr ON sr.sales_rank = 1;
