WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 10000
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY SUM(co.total_revenue) DESC) AS revenue_rank
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(co.total_revenue) > 50000
)
SELECT tc.c_custkey, tc.c_name, tc.c_acctbal, 
       rs.s_suppkey, rs.s_name, rs.s_acctbal AS supplier_acctbal
FROM TopCustomers tc
JOIN RankedSuppliers rs ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100
)
WHERE tc.revenue_rank <= 10
ORDER BY tc.c_custkey, rs.s_acctbal DESC;
