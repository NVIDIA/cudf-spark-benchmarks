
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    sd.region_name,
    sd.nation_name,
    sd.supplier_name,
    sd.part_count,
    sd.total_supply_cost,
    CONCAT('Supplier ', sd.supplier_name, ' from ', sd.nation_name, ' in ', sd.region_name, ' has ', sd.part_count, ' unique parts with a total supply cost of $', CAST(sd.total_supply_cost AS VARCHAR(20))) AS description
FROM 
    SupplierDetails sd
ORDER BY 
    sd.region_name, sd.nation_name, sd.total_supply_cost DESC;
