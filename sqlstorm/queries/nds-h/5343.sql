WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
), 
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice < 500
), 
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name AS customer_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
), 
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    oi.customer_name,
    oi.o_orderkey,
    oi.o_totalprice,
    si.nation,
    si.s_name AS supplier_name,
    pi.p_name AS part_name,
    pi.p_retailprice,
    ls.total_revenue
FROM OrderSummary oi
JOIN LineItemStats ls ON oi.o_orderkey = ls.l_orderkey
JOIN partsupp ps ON ls.l_orderkey = ps.ps_partkey
JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN PartInfo pi ON ps.ps_partkey = pi.p_partkey
WHERE ls.total_revenue > 1000
ORDER BY oi.o_orderdate DESC, total_revenue DESC
LIMIT 50;