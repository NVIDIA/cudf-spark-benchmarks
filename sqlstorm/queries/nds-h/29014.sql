WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        COUNT(ps.ps_supplycost) AS supply_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 25
        AND s.s_acctbal > 5000
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, s.s_comment
),
NationRegionDetails AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    p.p_name,
    p.short_comment,
    n.nation_name,
    n.region_name,
    CONCAT('Supplier: ', p.supplier_name, ' | Count: ', p.supply_count, ' | Nation: ', n.nation_name, ' in ', n.region_name) AS detail_summary
FROM 
    PartSupplierDetails p
JOIN 
    NationRegionDetails n ON p.supplier_name = n.nation_name
ORDER BY 
    p.p_name, n.region_name;
