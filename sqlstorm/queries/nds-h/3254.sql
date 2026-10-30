WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    p.p_name,
    COALESCE(r.total_sales, 0) AS total_sales_1996,
    ts.total_supply_cost,
    r.sales_rank
FROM 
    part p
LEFT JOIN 
    RankedSales r ON p.p_partkey = r.l_partkey AND r.sales_rank = 1
INNER JOIN 
    TopSuppliers ts ON ts.s_suppkey = r.l_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 50
    AND p.p_retailprice IS NOT NULL
ORDER BY 
    total_sales_1996 DESC, 
    ts.total_supply_cost ASC 
LIMIT 10;