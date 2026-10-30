WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        nation.n_name AS nation_name,
        ranked.s_name AS supplier_name,
        ranked.total_value
    FROM 
        RankedSuppliers ranked
    JOIN 
        nation ON ranked.s_nationkey = nation.n_nationkey
    JOIN 
        region r ON nation.n_regionkey = r.r_regionkey
    WHERE 
        ranked.rank <= 5
)
SELECT 
    ts.region_name,
    ts.nation_name,
    COUNT(*) AS supplier_count,
    SUM(ts.total_value) AS total_supply_value
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    ts.region_name, total_supply_value DESC;
