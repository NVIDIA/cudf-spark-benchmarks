WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost, p.p_name, p.p_brand
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty < 200
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_orderkey
)
SELECT OD.c_name, OD.o_orderkey, OD.o_totalprice, LRD.revenue, 
       PD.p_name, PD.p_brand, SD.nation_name, SD.s_name
FROM OrderDetails OD
JOIN LineItemDetails LRD ON OD.o_orderkey = LRD.l_orderkey
JOIN PartSupplierDetails PD ON LRD.revenue > 0
JOIN SupplierDetails SD ON PD.ps_suppkey = SD.s_suppkey
WHERE SD.nation_name = 'USA'
ORDER BY OD.o_totalprice DESC, LRD.revenue DESC
LIMIT 50;