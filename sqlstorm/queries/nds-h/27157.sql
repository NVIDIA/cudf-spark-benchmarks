WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00 AND
        s.s_comment LIKE '%important%'
), FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal < (SELECT AVG(c_acctbal) FROM customer) AND
        n.n_name IN ('Germany', 'France')
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.c_acctbal,
    f.n_name,
    r.s_name AS top_supplier,
    r.p_name AS top_part,
    r.s_acctbal AS supplier_acctbal
FROM 
    FilteredCustomers f
JOIN 
    RankedSuppliers r ON f.c_custkey = r.s_suppkey
WHERE 
    r.rank = 1
ORDER BY 
    f.c_acctbal, r.s_acctbal DESC;
