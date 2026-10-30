
WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
        AND s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
), FilteredSuppliers AS (
    SELECT 
        supp.* 
    FROM 
        SupplierOrderStats supp
    WHERE 
        supp.total_orders > (
            SELECT AVG(total_orders)
            FROM SupplierOrderStats
        ) 
        OR supp.total_revenue IS NULL
), PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(li.l_quantity), 0) AS total_quantity
    FROM
        part p 
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice)
            FROM part p2
            WHERE p2.p_container IS NOT NULL
        )
    GROUP BY 
        p.p_partkey, p.p_name
), OverlappingSuppliers AS (
    SELECT 
        fs.s_suppkey,
        fs.s_name,
        pp.p_partkey,
        pp.p_name,
        LEAD(pp.p_name) OVER (PARTITION BY fs.s_suppkey ORDER BY pp.p_partkey) AS next_part
    FROM 
        FilteredSuppliers fs
    JOIN  
        partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    JOIN 
        PopularParts pp ON ps.ps_partkey = pp.p_partkey
)

SELECT 
    os.s_suppkey, 
    os.s_name, 
    COUNT(DISTINCT os.p_partkey) AS unique_parts,
    SUM(pp.total_quantity) AS total_popularity,
    CASE 
        WHEN SUM(pp.total_quantity) > 100 THEN 'Highly Popular'
        WHEN SUM(pp.total_quantity) BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular' 
    END AS popularity_category,
    COUNT(*) FILTER (WHERE os.next_part IS NOT NULL) AS overlapping_part_variants
FROM 
    OverlappingSuppliers os
JOIN 
    PopularParts pp ON os.p_partkey = pp.p_partkey
GROUP BY 
    os.s_suppkey, os.s_name
HAVING 
    COUNT(DISTINCT os.p_partkey) > 2 
    AND SUM(pp.total_quantity) IS NOT NULL
ORDER BY 
    total_popularity DESC
LIMIT 10 OFFSET 5;
