WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_brand, p_size, p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rn
    FROM part
), 
SupplierCost AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
), 
CustomerOrders AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
), 
HighValueCustomers AS (
    SELECT c_name FROM CustomerOrders
    WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)

SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       s.s_name AS supplier_name, 
       rp.p_name, 
       rp.p_brand, 
       rp.p_size, 
       rp.p_retailprice, 
       sc.total_cost,
       cv.c_name AS high_value_customer
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
JOIN RecursivePart rp ON rp.p_partkey = sc.ps_partkey
LEFT JOIN HighValueCustomers cv ON cv.c_name = s.s_comment
WHERE rp.rn <= 5
ORDER BY region_name, nation_name, supplier_name;
