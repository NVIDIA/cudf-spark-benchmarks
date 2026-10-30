WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        p.p_mfgr,
        REPLACE(p.p_comment, 'obsolete', 'updated') AS updated_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY LENGTH(p.p_name) DESC) AS rn
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS contact_info,
        s.s_acctbal,
        SUBSTR(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.name_length,
    rp.updated_comment,
    si.contact_info,
    od.total_price,
    od.part_count
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_partkey % 10 = si.s_suppkey % 10
JOIN 
    OrderDetails od ON rp.p_partkey = od.o_orderkey % 100
WHERE 
    rp.rn = 1 
ORDER BY 
    total_price DESC, name_length DESC;