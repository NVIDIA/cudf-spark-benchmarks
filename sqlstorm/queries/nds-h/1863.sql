WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l.l_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(rs.s_name, 'N/A') AS best_supplier,
    co.order_count,
    CASE 
        WHEN co.order_count > 10 THEN 'Frequent Customer'
        ELSE 'Occasional Customer'
    END AS customer_type
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    TotalSales ts ON ts.l_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = ps.ps_suppkey AND rs.rank = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')
    ) LIMIT 1)
WHERE 
    p.p_retailprice > 100.00 AND (p.p_comment IS NOT NULL OR p.p_comment LIKE '%fragile%')
ORDER BY 
    total_sales DESC, p.p_name ASC;