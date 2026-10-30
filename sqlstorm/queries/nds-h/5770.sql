WITH NationSupplier AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrder AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_ordervalue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
OrderLine AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT ns.n_name, ns.total_acctbal, ps.total_supplycost, co.total_ordervalue, ol.total_lines
FROM NationSupplier ns
JOIN PartSupplier ps ON ns.n_name = 'USA'  
JOIN CustomerOrder co ON co.total_ordervalue > 100000  
JOIN OrderLine ol ON ol.total_lines > 5  
ORDER BY ns.total_acctbal DESC, ps.total_supplycost DESC
LIMIT 10;