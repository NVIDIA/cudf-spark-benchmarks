WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS sales_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        sales_month
),
TopRegions AS (
    SELECT 
        n.n_name AS region_name,
        SUM(ps.ps_supplycost * pp.p_retailprice) AS region_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part pp ON ps.ps_partkey = pp.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        region_name
    ORDER BY 
        region_supply_cost DESC
    LIMIT 5
)
SELECT 
    ms.sales_month,
    ms.total_sales,
    ms.unique_customers,
    tr.region_name,
    tr.region_supply_cost
FROM 
    MonthlySales ms
LEFT JOIN 
    TopRegions tr ON tr.region_supply_cost > (SELECT AVG(region_supply_cost) FROM TopRegions)
ORDER BY 
    ms.sales_month DESC, 
    ms.total_sales DESC;
