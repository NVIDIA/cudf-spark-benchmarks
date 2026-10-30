WITH FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 10000 AND o.o_orderstatus = 'O'
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name, s.s_acctbal, s.s_comment
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregateStats AS (
    SELECT fo.o_orderkey, COUNT(DISTINCT psd.ps_partkey) AS part_count, SUM(psd.s_acctbal) AS total_acct_bal
    FROM FilteredOrders fo
    JOIN lineitem l ON fo.o_orderkey = l.l_orderkey
    JOIN PartSupplierDetails psd ON l.l_partkey = psd.ps_partkey
    GROUP BY fo.o_orderkey
)
SELECT fo.o_orderkey, fo.o_orderdate, fo.o_totalprice, fo.c_name, psd.part_count, psd.total_acct_bal
FROM FilteredOrders fo
JOIN AggregateStats psd ON fo.o_orderkey = psd.o_orderkey
WHERE fo.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY fo.o_orderdate DESC, psd.total_acct_bal DESC;
