
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 5
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT co.c_name AS Customer, s.s_name AS Supplier, p.p_name AS Part, 
       SUM(oi.o_totalprice) AS OrderTotal, pd.total_quantity AS TotalQuantity, 
       ts.total_cost AS SupplierCost
FROM CustomerOrders co 
JOIN orders oi ON co.c_custkey = oi.o_custkey
JOIN lineitem l ON oi.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey 
JOIN PartDetails pd ON p.p_partkey = pd.p_partkey
WHERE oi.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY co.c_name, s.s_name, p.p_name, pd.total_quantity, ts.total_cost
ORDER BY OrderTotal DESC;
