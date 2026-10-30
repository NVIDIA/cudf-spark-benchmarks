WITH  CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
TopCustomers AS (
    SELECT cs.c_custkey, cs.c_name, cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM CustomerSales cs
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name,
           ps.ps_supplycost, ps.ps_availqty,
           COALESCE(NULLIF(s.s_acctbal, 0), NULL) AS adjusted_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
AggregatedSupplierCost AS (
    SELECT spd.p_partkey, 
           SUM(spd.ps_supplycost * spd.ps_availqty) AS total_supply_cost
    FROM SupplierPartDetails spd
    GROUP BY spd.p_partkey
)
SELECT c.c_name, c.total_sales, 
       spd.s_name, spd.p_name, 
       spd.adjusted_acctbal, 
       COALESCE(cost.total_supply_cost, 0) AS supply_cost,
       CASE 
           WHEN c.total_sales > 50000 THEN 'High Value'
           WHEN c.total_sales BETWEEN 20000 AND 50000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM TopCustomers c
LEFT JOIN SupplierPartDetails spd ON c.c_custkey = spd.s_suppkey
LEFT JOIN AggregatedSupplierCost cost ON spd.p_partkey = cost.p_partkey
WHERE spd.ps_supplycost IS NOT NULL 
AND c.sales_rank <= 10
ORDER BY c.total_sales DESC, spd.p_name;
