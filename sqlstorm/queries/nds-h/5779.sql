WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 5000
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM lineitem l
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
)
SELECT 
    si.nation_name,
    COUNT(DISTINCT hvo.o_orderkey) AS total_orders,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue,
    AVG(si.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
FROM SupplierInfo si
JOIN PartSupplier ps ON si.s_suppkey = ps.ps_suppkey
JOIN OrderLineItems ol ON ps.ps_partkey = ol.l_partkey
JOIN HighValueOrders hvo ON ol.l_orderkey = hvo.o_orderkey
GROUP BY si.nation_name
ORDER BY total_revenue DESC;
