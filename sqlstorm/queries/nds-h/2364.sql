WITH RankedSales AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l_partkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01'
        AND l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l_orderkey, l_partkey, l_suppkey
),
TopSuppliers AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        SUM(ps_availqty) AS total_availqty,
        AVG(ps_supplycost) AS avg_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(RS.total_sales, 0) AS total_sales,
    TS.total_availqty,
    TS.avg_supplycost,
    n.n_name AS nation_name,
    CASE 
        WHEN TS.avg_supplycost IS NULL THEN 'No Supplier'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    RankedSales RS ON p.p_partkey = RS.l_partkey AND RS.sales_rank = 1
LEFT JOIN 
    TopSuppliers TS ON p.p_partkey = TS.ps_partkey
JOIN 
    supplier s ON TS.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10
    AND p.p_container NOT IN ('WRAP', 'BOX')
ORDER BY 
    total_sales DESC, 
    p.p_partkey
LIMIT 50;