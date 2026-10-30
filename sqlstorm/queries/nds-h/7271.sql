WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
BestSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM RankedSuppliers s
    JOIN nation n ON s.n_name = n.n_name
    WHERE s.rn <= 5
),
ProductDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        b.s_name AS best_supplier
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        BestSuppliers b ON ps.ps_suppkey = b.s_suppkey
)
SELECT 
    pd.p_name, 
    SUM(pd.ps_availqty * pd.ps_supplycost) AS total_value, 
    b.n_name AS nation_name
FROM 
    ProductDetails pd
JOIN 
    BestSuppliers b ON pd.best_supplier = b.s_name
WHERE 
    pd.ps_availqty > 100
GROUP BY 
    pd.p_name, b.n_name
ORDER BY 
    total_value DESC
LIMIT 10;
