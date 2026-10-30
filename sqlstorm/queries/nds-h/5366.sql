WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
), SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000
), DetailedLineItems AS (
    SELECT li.*, ps.ps_supplycost, p.p_name, p.p_brand
    FROM lineitem li
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE li.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sd.s_name,
    sd.nation_name,
    dli.p_name,
    dli.l_quantity,
    dli.l_extendedprice,
    dli.l_discount,
    dli.l_tax
FROM RankedOrders ro
JOIN DetailedLineItems dli ON ro.o_orderkey = dli.l_orderkey
JOIN SupplierDetails sd ON dli.l_suppkey = sd.s_suppkey
WHERE ro.rank_order <= 10
ORDER BY ro.o_totalprice DESC, sd.s_name;