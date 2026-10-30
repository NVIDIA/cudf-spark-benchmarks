WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_container,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_container
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_mktsegment,
    pi.p_name,
    pi.p_brand,
    pi.p_retailprice,
    si.s_name AS top_supplier,
    si.s_acctbal AS top_supplier_acctbal,
    pi.total_suppliers
FROM RankedOrders ro
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN PartDetails pi ON l.l_partkey = pi.p_partkey
JOIN SupplierInfo si ON pi.p_partkey = si.ps_partkey AND si.supplier_rank = 1
WHERE ro.order_rank <= 10 AND pi.total_suppliers > 5
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;
