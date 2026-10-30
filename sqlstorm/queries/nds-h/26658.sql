WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.region_name ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails s
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.nation_name,
    ts.region_name,
    ts.total_available_quantity,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.region_name, ts.total_supply_cost DESC;
