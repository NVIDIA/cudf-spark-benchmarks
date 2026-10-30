
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
FilteredSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.part_count,
        rs.total_supply_value,
        rs.rank_in_nation
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_in_nation <= 3
)
SELECT 
    f.s_suppkey,
    f.s_name,
    f.nation_name,
    f.part_count,
    f.total_supply_value,
    (SELECT 
         SUM(o.o_totalprice) 
     FROM 
         orders o 
     JOIN 
         lineitem l ON o.o_orderkey = l.l_orderkey
     WHERE 
         l.l_suppkey = f.s_suppkey) AS total_orders_value
FROM 
    FilteredSuppliers f
ORDER BY 
    f.nation_name, f.total_supply_value DESC;
