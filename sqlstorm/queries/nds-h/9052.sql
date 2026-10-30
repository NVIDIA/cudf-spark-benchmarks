WITH NationSupplier AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartSummary AS (
    SELECT p.p_name, COUNT(ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
),
CustomerOrders AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_name
),
LineItemDetail AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, ns.total_acctbal, ps.p_name, ps.supplier_count, ps.avg_supplycost,
       co.c_name, co.order_count, co.total_spent, lid.total_value
FROM NationSupplier ns
JOIN PartSummary ps ON ns.n_name = SUBSTRING(ps.p_name FROM 1 FOR 25) 
JOIN CustomerOrders co ON co.order_count > 10
JOIN LineItemDetail lid ON lid.total_value > 1000
ORDER BY ns.total_acctbal DESC, co.total_spent DESC, ps.avg_supplycost ASC
LIMIT 50;