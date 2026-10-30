WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.nation_name,
        ss.total_supply_value,
        ss.unique_parts_supplied,
        RANK() OVER (PARTITION BY ss.nation_name ORDER BY ss.total_supply_value DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ts.nation_name,
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_value,
    ts.unique_parts_supplied
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.nation_name, ts.total_supply_value DESC;
