WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.p_partkey,
    r.p_name,
    ss.part_count,
    ss.total_supplycost,
    od.revenue,
    od.unique_parts
FROM 
    RankedParts r
LEFT JOIN 
    SupplierSummary ss ON r.p_partkey = ss.part_count
LEFT JOIN 
    OrderDetails od ON r.p_partkey = od.unique_parts
WHERE 
    r.rank <= 5
    AND (ss.total_supplycost IS NULL OR ss.total_supplycost > 20000)
UNION ALL
SELECT 
    NULL AS p_partkey,
    'Total' AS p_name,
    COUNT(*) AS part_count,
    SUM(ss.total_supplycost) AS total_supplycost,
    SUM(od.revenue) AS revenue,
    COUNT(od.unique_parts) AS unique_parts
FROM 
    SupplierSummary ss
FULL OUTER JOIN 
    OrderDetails od ON ss.part_count = od.unique_parts
WHERE 
    ss.part_count IS NOT NULL OR od.unique_parts IS NOT NULL;