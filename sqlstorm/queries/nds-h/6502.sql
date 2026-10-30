WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty, COUNT(*) AS sup_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, ps.ps_partkey, ps.sup_count, co.c_name, co.o_orderkey, co.o_orderdate, lis.total_price
FROM NationSupplier ns
JOIN PartSupplier ps ON ns.s_suppkey = ps.ps_suppkey
JOIN CustomerOrders co ON ns.n_name = co.c_name
JOIN LineItemSummary lis ON co.o_orderkey = lis.l_orderkey
WHERE ps.total_availqty > 1000 AND lis.total_price > 5000
ORDER BY ns.n_name, co.o_orderdate DESC
LIMIT 50;
