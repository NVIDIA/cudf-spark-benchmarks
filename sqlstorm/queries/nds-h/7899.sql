WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        r.r_name, 
        COUNT(rs.s_suppkey) AS supplier_count, 
        AVG(rs.total_supply_value) AS avg_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    hvs.r_name, 
    hvs.supplier_count, 
    hvs.avg_supply_value
FROM 
    HighValueSuppliers hvs
ORDER BY 
    hvs.avg_supply_value DESC;
