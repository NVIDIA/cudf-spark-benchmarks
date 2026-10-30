WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    s.s_suppkey,
    s.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    (SELECT COUNT(*) FROM HighValueOrders hvo WHERE hvo.o_custkey = c.c_custkey) AS high_value_order_count,
    CASE 
        WHEN s.rn = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_rank
FROM 
    RankedSuppliers s
LEFT JOIN 
    TotalSales ts ON s.s_suppkey = ts.l_suppkey
JOIN 
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    ts.total_sales IS NOT NULL OR ts.total_sales IS NULL
ORDER BY 
    total_sales DESC, s.s_name;
