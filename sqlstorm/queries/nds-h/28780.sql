WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%special%'
), 
SuppliersWithHighPriority AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000 AND s.s_comment LIKE '%loyal%'
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value, 
        o.o_orderstatus, 
        o.o_orderdate,
        o.o_comment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_comment
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    shp.s_name, 
    shp.nation_name, 
    od.total_value, 
    od.o_orderstatus, 
    od.o_orderdate,
    od.o_comment
FROM 
    RankedParts rp
JOIN 
    SuppliersWithHighPriority shp ON rp.rn = 1
JOIN 
    OrderDetails od ON od.total_value > 50000
WHERE 
    rp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty < 100
    )
ORDER BY 
    rp.p_brand, od.o_orderdate DESC;