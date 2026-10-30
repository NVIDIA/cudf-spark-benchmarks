WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT rs.nation_name, rs.s_suppkey, rs.s_name, rs.s_acctbal
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT p.p_name, ts.nation_name, ts.s_name, SUM(os.total_revenue) AS total_revenue_generated
FROM TopSuppliers ts
JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN OrderSummary os ON os.o_custkey = ts.s_suppkey
GROUP BY p.p_name, ts.nation_name, ts.s_name
ORDER BY total_revenue_generated DESC
LIMIT 10;
