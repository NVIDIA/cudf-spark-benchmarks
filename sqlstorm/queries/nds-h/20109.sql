WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND o.o_orderstatus IN ('O', 'F')
),
PartCount AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_partkey) AS part_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_supplycost,
    COALESCE(RS.s_name, 'Unknown Supplier') AS supplier_name,
    F.total_order_value,
    COALESCE(NULLIF(FC.part_count, 0), -1) AS order_part_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey AND RS.supplier_rank <= 3
LEFT JOIN 
    (SELECT 
        o.o_orderkey,
        SUM(o.o_totalprice) AS total_order_value
     FROM 
        FilteredOrders o
     GROUP BY 
        o.o_orderkey) F ON F.o_orderkey = ps.ps_partkey
LEFT JOIN 
    PartCount FC ON FC.l_orderkey = ps.ps_partkey
WHERE 
    (p.p_size = (SELECT MAX(p2.p_size) FROM part p2) OR p.p_size IS NULL)
    AND p.p_retailprice BETWEEN 100.00 AND 1000.00
ORDER BY 
    p.p_name, 
    RS.s_name DESC NULLS LAST;