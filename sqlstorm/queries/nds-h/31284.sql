WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSales AS (
    SELECT 
        c.c_nationkey,
        MAX(s.total_sales) AS max_sales
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    GROUP BY 
        c.c_nationkey
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_sales, 0) AS supplier_sales,
    COALESCE(ts.max_sales, 0) AS nation_max_sales,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) > COALESCE(ts.max_sales, 0) THEN 'Above Average'
        WHEN COALESCE(ss.total_sales, 0) < COALESCE(ts.max_sales, 0) THEN 'Below Average'
        ELSE 'Average'
    END AS sales_comparison
FROM 
    part p
LEFT JOIN 
    SupplierSales ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    TopSales ts ON p.p_partkey = ts.c_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    supplier_sales DESC, nation_max_sales ASC;