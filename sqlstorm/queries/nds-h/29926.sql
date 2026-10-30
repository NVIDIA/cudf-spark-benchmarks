WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(NULLIF(l.l_extendedprice, 0)) AS avg_price,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.part_count, 
        rs.total_avail_qty, 
        rs.total_supply_cost, 
        rs.avg_price
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    fs.s_name, 
    fs.part_count, 
    fs.total_avail_qty, 
    fs.total_supply_cost, 
    fs.avg_price,
    CONCAT('Supplier ', fs.s_name, ' has ', fs.part_count, ' unique parts available, with a total available quantity of ', fs.total_avail_qty, 
           '. Total supply cost is ', fs.total_supply_cost, ' and average price per part is ', ROUND(fs.avg_price, 2)) AS supplier_summary
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.total_avail_qty DESC;
