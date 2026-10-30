WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), ProductInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size IS NULL THEN 'Size Not Specified'
            ELSE CONCAT('Size: ', p.p_size)
        END AS size_info,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    pi.size_info,
    pi.supplier_count,
    COALESCE(r.s_name, 'No Supplier') AS best_supplier,
    COALESCE(r.s_acctbal, 0) AS supplier_balance,
    h.total_spent
FROM 
    ProductInfo pi
LEFT JOIN 
    RankedSuppliers r ON pi.p_partkey = r.s_suppkey AND r.rank = 1
LEFT JOIN 
    HighValueCustomers h ON r.s_suppkey = h.c_custkey
WHERE 
    (pi.supplier_count > 2 OR r.s_acctbal IS NULL)
ORDER BY 
    pi.p_partkey DESC, total_spent DESC, supplier_balance ASC;
