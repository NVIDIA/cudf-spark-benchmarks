WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS account_status
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    SUM(COALESCE(l.l_extendedprice, 0)) AS total_sales,
    AVG(l.l_discount) AS avg_discount,
    MAX(s.total_cost) AS max_supplier_cost,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size IS NOT NULL AND p.p_size > 0
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr
HAVING 
    COUNT(CASE WHEN l.l_shipdate >= '1997-01-01' THEN 1 END) > 5
ORDER BY 
    total_sales DESC, sales_rank;