WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_mfgr, ' | ', p.p_brand, ' | ', p.p_type) AS part_details,
        p.p_retailprice
    FROM 
        part p 
    WHERE 
        p.p_size IN (10, 20, 30) 
        AND p.p_retailprice BETWEEN 50 AND 500
), CustomersWithComments AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        LENGTH(c.c_comment) AS comment_length,
        SUBSTRING(c.c_comment FROM 1 FOR 20) AS short_comment
    FROM 
        customer c 
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    cs.c_name,
    cs.comment_length,
    pp.p_name,
    rs.s_name AS supplier_name,
    pp.part_details,
    pp.p_retailprice
FROM 
    CustomersWithComments cs
JOIN 
    orders o ON cs.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    FilteredParts pp ON li.l_partkey = pp.p_partkey
JOIN 
    RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
WHERE 
    rs.rank <= 5
ORDER BY 
    cs.comment_length DESC, 
    pp.p_retailprice ASC;
