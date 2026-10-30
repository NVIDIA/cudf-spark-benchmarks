
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
TopPartSuppliers AS (
    SELECT 
        p.ps_partkey, 
        rs.s_name, 
        rs.nation_name, 
        rs.rank 
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN HighValueParts p ON ps.ps_partkey = p.ps_partkey
)
SELECT 
    p.ps_partkey,
    p.total_supply_value,
    ts.s_name,
    ts.nation_name
FROM HighValueParts p
JOIN TopPartSuppliers ts ON p.ps_partkey = ts.ps_partkey
ORDER BY p.total_supply_value DESC, ts.rank ASC;
