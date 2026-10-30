WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
        AND o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    DISTINCT p.p_name,
    p.p_brand,
    p.p_retailprice,
    ts.s_name,
    ts.total_sales
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE
    p.p_container LIKE '%BOX%'
    AND p.p_size IN (10, 20, 30)
ORDER BY 
    ts.total_sales DESC, p.p_retailprice ASC;