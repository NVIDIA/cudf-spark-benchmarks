WITH  CTE_TotalSales AS (
    SELECT
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
CTE_AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        CTE_TotalSales
), 
CTE_SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ts.total_sales) AS regional_sales,
    MAX(ss.total_supply_cost) AS max_supplier_cost,
    a.avg_sales AS average_sales
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CTE_TotalSales ts ON c.c_custkey = ts.c_custkey
LEFT JOIN 
    CTE_SupplierStats ss ON ss.part_count > 1
CROSS JOIN 
    CTE_AvgSales a
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, n.n_name, a.avg_sales
HAVING 
    SUM(ts.total_sales) > (SELECT COALESCE(AVG(total_sales), 0) FROM CTE_TotalSales)
ORDER BY 
    regional_sales DESC;
