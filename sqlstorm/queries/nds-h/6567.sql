WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name AS customer_name,
           ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_type LIKE '%metals%'
),
MostProfitableLines AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS profit
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT r.s_name, r.nation_name, h.customer_name, h.o_orderkey, h.o_totalprice, 
       sp.p_name, sp.ps_availqty, sp.ps_supplycost, mp.profit
FROM RankedSuppliers r
JOIN HighValueOrders h ON r.rank <= 5
JOIN SupplierParts sp ON r.s_suppkey = sp.ps_suppkey
JOIN MostProfitableLines mp ON h.o_orderkey = mp.l_orderkey
ORDER BY mp.profit DESC, h.o_totalprice DESC;