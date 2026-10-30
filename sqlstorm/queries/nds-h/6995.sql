WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.total_cost,
           RANK() OVER (ORDER BY s.total_cost DESC) AS rank
    FROM RankedSuppliers s
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cu.c_name, cu.order_count, cu.total_spent, ts.s_name, ts.total_cost
FROM CustomerOrders cu
JOIN TopSuppliers ts ON cu.total_spent > ts.total_cost
WHERE cu.order_count > 5
ORDER BY cu.total_spent DESC, ts.total_cost ASC;
