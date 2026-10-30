WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), LineItemDetails AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    WHERE lo.l_shipdate < '1997-01-01'
    GROUP BY lo.l_orderkey
), FinalSummary AS (
    SELECT cp.s_suppkey, cp.s_name, co.o_orderkey, co.o_orderdate, li.total_revenue
    FROM SupplierParts cp
    JOIN CustomerOrders co ON cp.s_suppkey = co.o_orderkey
    JOIN LineItemDetails li ON co.o_orderkey = li.l_orderkey
)
SELECT fs.s_suppkey, fs.s_name, COUNT(DISTINCT fs.o_orderkey) AS order_count, 
       SUM(fs.total_revenue) AS total_revenue, 
       AVG(fs.total_revenue) AS avg_revenue
FROM FinalSummary fs
GROUP BY fs.s_suppkey, fs.s_name
ORDER BY total_revenue DESC
LIMIT 10;
