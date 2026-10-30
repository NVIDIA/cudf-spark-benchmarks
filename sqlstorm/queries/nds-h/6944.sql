
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        r.r_name,
        r.r_regionkey,
        COUNT(sf.s_suppkey) AS supplier_count,
        SUM(sf.total_value) AS total_region_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers sf ON n.n_nationkey = sf.s_suppkey 
    WHERE 
        sf.rank <= 5
    GROUP BY 
        r.r_name, r.r_regionkey
)
SELECT 
    r.r_name,
    r.supplier_count,
    r.total_region_value,
    AVG(ps.ps_supplycost) AS avg_supplycost
FROM 
    HighValueSuppliers r
JOIN 
    partsupp ps ON r.supplier_count = ps.ps_partkey
GROUP BY 
    r.r_name, r.supplier_count, r.total_region_value
ORDER BY 
    r.total_region_value DESC;
