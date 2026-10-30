WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    sd.nation_name,
    STRING_AGG(CONCAT(sd.s_name, ': $', CAST(sd.total_supply_value AS STRING)), ', ') AS top_suppliers
FROM 
    SupplierDetails sd
GROUP BY 
    sd.nation_name
ORDER BY 
    sd.nation_name;
