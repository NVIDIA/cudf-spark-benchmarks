WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
)
SELECT 
    r.r_name AS region_name,
    sr.s_name AS supplier_name,
    sr.total_supply_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    SupplierRanking sr ON n.n_nationkey = sr.s_suppkey
WHERE 
    sr.rank <= 3
ORDER BY 
    r.r_name, sr.total_supply_value DESC;
