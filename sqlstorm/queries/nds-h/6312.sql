
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighestCostSuppliers AS (
    SELECT 
        rc.rnk,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        rc.total_supply_cost,
        n.n_nationkey
    FROM 
        RankedSuppliers rc
    JOIN 
        supplier s ON rc.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rc.rnk <= 3
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT hs.s_suppkey) AS supplier_count,
    SUM(hs.total_supply_cost) AS total_cost,
    AVG(hs.s_acctbal) AS avg_acct_balance
FROM 
    HighestCostSuppliers hs
JOIN 
    nation n ON hs.n_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_cost DESC;
