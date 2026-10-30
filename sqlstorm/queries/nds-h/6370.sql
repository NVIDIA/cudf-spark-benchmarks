
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS Region,
        n.n_name AS Nation,
        rs.s_suppkey,
        rs.s_name,
        rs.TotalSupplyCost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.RankInNation <= 5
)
SELECT 
    ts.Region, 
    ts.Nation, 
    COUNT(ts.s_suppkey) AS NumberOfTopSuppliers,
    AVG(ts.TotalSupplyCost) AS AvgTotalSupplyCost
FROM TopSuppliers ts
GROUP BY ts.Region, ts.Nation
ORDER BY ts.Region, ts.Nation;
