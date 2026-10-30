WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size >= 10 AND p.p_size <= 20
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        l.l_shipmode,
        l.l_quantity,
        l.l_discount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    fs.s_name AS supplier_name,
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.c_name,
    od.c_mktsegment,
    SUM(od.l_quantity * (1 - od.l_discount)) AS total_revenue
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN OrderDetails od ON ps.ps_partkey = od.o_orderkey
WHERE rp.rank <= 5
GROUP BY rp.p_name, rp.p_mfgr, fs.s_name, od.o_orderkey, od.o_orderdate, od.o_totalprice, od.c_name, od.c_mktsegment
ORDER BY total_revenue DESC;
