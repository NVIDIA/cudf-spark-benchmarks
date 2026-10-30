WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rs.nation_name
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.rank <= 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
OrderDetails AS (
    SELECT co.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.c_custkey
)
SELECT ts.nation_name, ts.s_name, ts.s_acctbal, od.total_revenue
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey = od.c_custkey
WHERE ts.s_acctbal > 10000
ORDER BY ts.nation_name, od.total_revenue DESC;
