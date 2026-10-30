WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(s.s_suppkey) AS supplier_count
    FROM
        RankedSuppliers s
    JOIN
        nation n ON n.n_nationkey = s.s_suppkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        s.supplier_rank <= 3
    GROUP BY
        r.r_name
)
SELECT 
    region_name,
    total_acctbal,
    supplier_count,
    CONCAT('Region ', region_name, ' has a total account balance of $', total_acctbal, ' from ', supplier_count, ' top suppliers.') AS summary
FROM 
    TopSuppliers
ORDER BY 
    total_acctbal DESC;
