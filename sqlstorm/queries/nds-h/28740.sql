WITH SupplierInfo AS (
    SELECT s.s_name AS supplier_name, 
           r.r_name AS region_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, r.r_name
), CustomerOrders AS (
    SELECT c.c_name AS customer_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
), AggregatedData AS (
    SELECT si.supplier_name, 
           si.region_name, 
           ci.customer_name, 
           ci.order_count, 
           ci.total_order_value, 
           ROW_NUMBER() OVER (PARTITION BY si.region_name, ci.customer_name ORDER BY si.total_supply_value DESC) AS ranking
    FROM SupplierInfo si
    JOIN CustomerOrders ci ON si.region_name = ci.customer_name
)

SELECT supplier_name, 
       region_name, 
       customer_name, 
       order_count, 
       total_order_value
FROM AggregatedData
WHERE ranking <= 5
ORDER BY region_name, total_order_value DESC;
