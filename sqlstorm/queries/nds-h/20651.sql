
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        pp.size_category
    FROM 
        partsupp ps
    JOIN 
        FilteredParts pp ON ps.ps_partkey = pp.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT fp.p_partkey) AS total_parts,
    SUM(sp.ps_availqty * sp.ps_supplycost) AS total_supply_cost,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    RANK() OVER (ORDER BY SUM(sp.ps_availqty * sp.ps_supplycost) DESC) AS supply_rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.ranking <= 5
LEFT JOIN 
    SupplierPartInfo sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey = sp.ps_partkey
WHERE 
    n.n_name IS NOT NULL
    AND (sp.ps_availqty - COALESCE((SELECT SUM(l.l_quantity) FROM lineitem l WHERE l.l_suppkey = s.s_suppkey), 0)) > 0
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT fp.p_partkey) > 0
ORDER BY 
    supply_rank ASC;
