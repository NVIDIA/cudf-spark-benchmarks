WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_retailprice, 
           p.p_comment, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
TopRegions AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
FinalOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           o.o_totalprice, 
           o.o_orderdate, 
           o.o_orderpriority, 
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority
    HAVING SUM(l.l_quantity) > 10
)
SELECT f.o_orderkey, 
       f.o_orderstatus, 
       f.o_orderdate, 
       f.total_line_item_price, 
       rp.p_name, 
       tr.r_name, 
       ts.s_name 
FROM FinalOrders f
JOIN RankedParts rp ON f.o_orderkey = rp.p_partkey
JOIN TopRegions tr ON rp.p_partkey = tr.r_regionkey
JOIN TopSuppliers ts ON f.o_orderkey = ts.s_suppkey
WHERE rp.price_rank = 1
ORDER BY f.o_orderdate DESC, f.total_line_item_price DESC
LIMIT 100;