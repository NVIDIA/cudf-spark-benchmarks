WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount, 
           AVG(l.l_quantity) AS avg_quantity, COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
), NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT sd.s_name, nr.r_name, co.c_name, co.o_orderkey, co.o_orderdate,
       ls.total_price_after_discount, ls.avg_quantity, ls.item_count
FROM SupplierDetails sd
JOIN LineItemSummary ls ON sd.s_suppkey = ls.l_orderkey
JOIN CustomerOrders co ON ls.l_orderkey = co.o_orderkey
JOIN NationRegion nr ON sd.s_nationkey = nr.n_nationkey
WHERE sd.ps_supplycost < 100.00
ORDER BY ls.total_price_after_discount DESC, co.o_orderdate DESC
LIMIT 50;
