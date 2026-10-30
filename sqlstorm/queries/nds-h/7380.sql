WITH PartSupplierData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrderData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
LineItemAnalysis AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales,
        COUNT(DISTINCT lo.l_linenumber) AS line_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
) 
SELECT 
    psd.p_name,
    psd.s_name,
    psd.ps_availqty,
    psd.ps_supplycost,
    cod.c_name,
    cod.o_orderkey,
    cod.o_orderdate,
    la.total_sales,
    la.line_count
FROM 
    PartSupplierData psd
JOIN 
    LineItemAnalysis la ON psd.p_partkey = la.l_orderkey
JOIN 
    CustomerOrderData cod ON cod.o_orderkey = la.l_orderkey
WHERE 
    psd.p_retailprice > 50 AND 
    cod.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    psd.p_name, la.total_sales DESC
LIMIT 100;