WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT 
        p_partkey,
        p_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank = 1
),
SuppliersInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.total_sales,
    s.s_name,
    s.s_acctbal,
    s.supplier_nation
FROM 
    TopSales t
LEFT JOIN 
    SuppliersInfo s ON t.p_partkey = s.p_partkey
WHERE 
    s.s_acctbal IS NOT NULL AND
    t.total_sales > (
        SELECT AVG(total_sales) 
        FROM TopSales
    )
ORDER BY 
    t.total_sales DESC, 
    s.s_acctbal DESC
LIMIT 10;
