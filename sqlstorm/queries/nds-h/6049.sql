
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_acctbal, l.l_quantity, l.l_discount, l.l_extendedprice
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= DATE '1997-01-01'
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ld.l_extendedprice) AS total_revenue
    FROM part p
    JOIN lineitem ld ON p.p_partkey = ld.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(ld.l_extendedprice) > 1000
)
SELECT d.o_orderkey, d.o_totalprice, d.c_name, d.c_acctbal, s.s_name AS supplier_name, 
       p.p_name AS part_name, p.total_revenue
FROM OrderDetails d
JOIN TopSuppliers s ON d.o_totalprice > (SELECT AVG(total_supply_cost) FROM TopSuppliers)
JOIN PartInfo p ON d.l_quantity > 10
ORDER BY d.o_orderkey, p.total_revenue DESC
LIMIT 100;
