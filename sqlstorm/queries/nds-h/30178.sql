
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
RankedSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales IS NULL THEN 0 
            ELSE total_sales 
        END AS effective_sales
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 10
)
SELECT 
    p.p_name, 
    COALESCE(SUM(line.l_extendedprice * (1 - line.l_discount)), 0) AS total_revenue,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    part p
LEFT JOIN 
    lineitem line ON p.p_partkey = line.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10
    AND p.p_retailprice BETWEEN 20.00 AND 100.00
    AND p.p_mfgr IN ('Manufacturer#1', 'Manufacturer#2')
GROUP BY 
    p.p_name
HAVING 
    COALESCE(SUM(line.l_extendedprice * (1 - line.l_discount)), 0) > (
        SELECT 
            AVG(effective_sales) 
        FROM 
            RankedSales
        WHERE 
            effective_sales > 0
    )
ORDER BY 
    total_revenue DESC
LIMIT 5;
