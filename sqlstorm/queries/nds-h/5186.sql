
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rnk
    FROM 
        SupplierSales ss
)
SELECT 
    ts.s_name,
    ps.p_name,
    ps.total_sales
FROM 
    TopSuppliers ts
JOIN 
    partsupp psupp ON ts.s_suppkey = psupp.ps_suppkey
JOIN 
    PartSales ps ON psupp.ps_partkey = ps.p_partkey
WHERE 
    ts.rnk <= 5
ORDER BY 
    ps.total_sales DESC;
