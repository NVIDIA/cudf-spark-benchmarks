
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
BestSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_address, 
        rs.nation, 
        rs.s_acctbal, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        rs.s_suppkey, rs.s_name, rs.s_address, rs.nation, rs.s_acctbal, p.p_name, p.p_brand
)
SELECT 
    b.nation, 
    b.s_name, 
    COUNT(DISTINCT b.p_name) AS product_count, 
    SUM(b.total_supply_cost) AS total_cost,
    CONCAT('Supplier: ', b.s_name, ', Products supplied: ', COUNT(DISTINCT b.p_name)) AS supplier_info
FROM 
    BestSuppliers b
GROUP BY 
    b.nation, b.s_name
ORDER BY 
    b.nation, total_cost DESC;
