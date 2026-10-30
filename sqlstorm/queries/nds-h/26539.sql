WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        )
),
FilteredSuppliers AS (
    SELECT 
        rs.s_name,
        rs.nation_name,
        rs.p_name,
        rs.ps_availqty,
        rs.ps_supplycost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    fs.nation_name, 
    COUNT(fs.s_name) AS supplier_count,
    SUM(fs.ps_supplycost) AS total_supply_cost,
    AVG(fs.ps_availqty) AS average_avail_quantity
FROM 
    FilteredSuppliers fs
GROUP BY 
    fs.nation_name
ORDER BY 
    supplier_count DESC, total_supply_cost DESC;
