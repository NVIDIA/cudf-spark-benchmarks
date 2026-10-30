
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        region r 
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        r.r_name
    HAVING 
        SUM(l.l_extendedprice) > 100000
)
SELECT 
    p.p_name,
    p.p_brand,
    tp.total_parts,
    tr.r_name,
    tr.total_revenue,
    ss.total_sales,
    CASE 
        WHEN ss.sales_rank <= 5 THEN 'Top Customer'
        ELSE 'Other Customer'
    END AS customer_category
FROM 
    part p
JOIN 
    FilteredSuppliers tp ON p.p_partkey = tp.total_parts
LEFT JOIN 
    SalesCTE ss ON ss.o_orderkey = (SELECT o.o_orderkey FROM orders o LIMIT 1)
JOIN 
    TopRegions tr ON tr.r_name = (SELECT r.r_name FROM region r LIMIT 1)
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size > (SELECT AVG(p2.p_size) FROM part p2 WHERE p2.p_size IS NOT NULL)
ORDER BY 
    tr.total_revenue DESC, 
    ss.total_sales DESC;
