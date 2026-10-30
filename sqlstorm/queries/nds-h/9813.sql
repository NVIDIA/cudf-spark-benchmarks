WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_name, 
        s.s_acctbal, 
        rs.total_supply_cost
    FROM 
        supplier s
    JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    n.n_name AS nation_name,
    SUM(ts.total_supply_cost) AS total_top_supplier_cost,
    AVG(ts.s_acctbal) AS average_account_balance
FROM 
    nation n
JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_top_supplier_cost DESC;
