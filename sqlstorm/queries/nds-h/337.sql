WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RNK
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_partkey
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)

SELECT 
    r.r_name,
    sp.p_name,
    sp.p_brand,
    SUM(ts.total_sales) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS average_account_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartInfo sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON sp.ps_suppkey = s.s_suppkey AND s.RNK <= 3
LEFT JOIN 
    TotalSales ts ON sp.ps_partkey = ts.l_partkey
WHERE 
    l.l_returnflag = 'N' AND
    (s.s_acctbal IS NOT NULL OR s.s_acctbal < 5000) 
GROUP BY 
    r.r_name, sp.p_name, sp.p_brand
HAVING 
    SUM(ts.total_sales) > 10000
ORDER BY 
    total_sales DESC, average_account_balance ASC;