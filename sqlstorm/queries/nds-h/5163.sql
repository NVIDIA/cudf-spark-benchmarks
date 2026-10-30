WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           l.l_discount, l.l_returnflag, l.l_linestatus
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT r.r_name, SUM(f.l_extendedprice * (1 - f.l_discount)) AS revenue,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       COUNT(DISTINCT rq.s_suppkey) AS supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers rq ON s.s_suppkey = rq.s_suppkey AND rq.supplier_rank <= 5
JOIN partsupp ps ON rq.s_suppkey = ps.ps_suppkey
JOIN FilteredLineItems f ON ps.ps_partkey = f.l_partkey
JOIN HighValueCustomers c ON f.l_orderkey = c.c_custkey
GROUP BY r.r_name
ORDER BY revenue DESC;