WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 30 AND 
        s.s_acctbal > 5000
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        NS.n_name,
        COUNT(DISTINCT RS.s_suppkey) AS supplier_count,
        SUM(RS.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers RS
    JOIN 
        supplier S ON RS.s_suppkey = S.s_suppkey
    JOIN 
        nation NS ON S.s_nationkey = NS.n_nationkey
    JOIN 
        region R ON NS.n_regionkey = R.r_regionkey
    WHERE 
        RS.rank <= 3
    GROUP BY 
        R.r_name, NS.n_name
)
SELECT 
    r_name,
    n_name,
    supplier_count,
    total_acctbal,
    supplier_count * 1.0 / SUM(supplier_count) OVER() AS percentage_share
FROM 
    TopSuppliers
ORDER BY 
    total_acctbal DESC, supplier_count DESC;
