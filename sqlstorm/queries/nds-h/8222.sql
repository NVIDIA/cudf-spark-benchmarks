WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    ORDER BY s.total_supply_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrders c
    WHERE c.total_spent > 10000
)
SELECT DISTINCT 
    su.s_name AS supplier_name, 
    cu.c_name AS customer_name, 
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN HighValueCustomers cu ON o.o_custkey = cu.c_custkey
JOIN TopSuppliers su ON li.l_suppkey = su.s_suppkey
WHERE li.l_shipdate >= '1997-01-01' AND li.l_returnflag = 'N'
GROUP BY su.s_name, cu.c_name
ORDER BY total_value DESC;