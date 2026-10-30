
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.TotalSupplyCost) AS TotalSupplierCost,
        COUNT(ss.s_suppkey) AS TotalSuppliers
    FROM 
        nation n
    JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_regionkey,
    r.r_name,
    ns.TotalSupplierCost,
    ns.TotalSuppliers
FROM 
    region r
JOIN 
    NationSummary ns ON r.r_regionkey = ns.n_nationkey
ORDER BY 
    ns.TotalSupplierCost DESC
LIMIT 10;
