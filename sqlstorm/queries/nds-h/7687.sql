WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.total_supplycost,
           RANK() OVER (ORDER BY s.total_supplycost DESC) AS rank
    FROM RankedSuppliers s
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    ts.total_supplycost
FROM CustomerOrders cs
JOIN TopSuppliers ts ON cs.total_spent > ts.total_supplycost
WHERE ts.rank <= 10
ORDER BY cs.total_spent DESC, ts.total_supplycost DESC;
