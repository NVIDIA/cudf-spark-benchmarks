WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_quantity) AS total_quantity_sold,
        AVG(li.l_extendedprice) AS average_price
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(li.l_quantity) > 100
)
SELECT 
    rs.nation_name,
    rs.s_name,
    rs.parts_supplied,
    pp.p_name,
    pp.total_quantity_sold,
    pp.average_price
FROM 
    RankedSuppliers rs
JOIN 
    PopularParts pp ON rs.parts_supplied > (SELECT AVG(parts_supplied) FROM RankedSuppliers) 
WHERE 
    rs.rank <= 3
ORDER BY 
    rs.nation_name, rs.parts_supplied DESC;
