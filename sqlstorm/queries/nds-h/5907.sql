
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), RevenueAnalysis AS (
    SELECT os.o_custkey, cd.c_name, cd.region_name,
           SUM(os.total_revenue) AS total_customer_revenue,
           COUNT(os.o_orderkey) AS total_orders
    FROM OrderSummary os
    JOIN CustomerDetails cd ON os.o_custkey = cd.c_custkey
    GROUP BY os.o_custkey, cd.c_name, cd.region_name
)
SELECT ra.region_name, AVG(sd.avg_supply_cost) AS avg_supplier_cost,
       SUM(ra.total_customer_revenue) AS total_revenue_by_region,
       COUNT(DISTINCT ra.o_custkey) AS unique_customers
FROM RevenueAnalysis ra
JOIN SupplierDetails sd ON ra.o_custkey = sd.s_nationkey
GROUP BY ra.region_name
ORDER BY total_revenue_by_region DESC;
