WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregateData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(CASE WHEN r.r_name = 'ASIA' THEN ps.ps_supplycost ELSE 0 END) AS total_supplycost_asia,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ad.p_partkey,
    ad.p_name,
    ad.supplier_count,
    ad.total_supplycost_asia,
    ad.avg_acctbal,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier
FROM 
    AggregateData ad
LEFT JOIN 
    RankedSuppliers rs ON ad.p_partkey = rs.s_suppkey AND rs.rank = 1
WHERE 
    ad.total_supplycost_asia > 1000
ORDER BY 
    ad.avg_acctbal DESC;
