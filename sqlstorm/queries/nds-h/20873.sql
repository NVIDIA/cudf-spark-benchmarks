WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice ASC) AS rnk,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS total_parts
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
    AND 
        (p.p_retailprice IS NOT NULL OR p.p_container IS NOT NULL)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        AVG(s.s_acctbal) > 1000
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    sd.s_name,
    sd.total_supplycost,
    os.total_revenue,
    os.total_lines,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(os.total_revenue AS STRING)
    END AS revenue_status,
    CASE 
        WHEN r.total_parts > 5 
        THEN 'High Availability'
        ELSE 'Limited Stock'
    END AS part_availability_status
FROM 
    RankedParts r
LEFT JOIN 
    SupplierDetails sd ON r.p_partkey = sd.s_suppkey
LEFT JOIN 
    OrderStats os ON r.p_partkey = os.o_orderkey
WHERE 
    (rnk = 1 AND sd.s_acctbal IS NOT NULL) OR (os.total_revenue > 0 AND r.total_parts < 10)
ORDER BY 
    r.p_brand, sd.total_supplycost DESC NULLS LAST;