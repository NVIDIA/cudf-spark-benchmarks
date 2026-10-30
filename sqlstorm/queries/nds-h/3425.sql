
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
TopRegions AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
FinalReport AS (
    SELECT 
        tr.nation_name,
        tr.total_sales,
        sd.s_name,
        sd.total_supply_cost,
        COALESCE(tr.total_sales - sd.total_supply_cost, tr.total_sales) AS net_sales
    FROM 
        TopRegions tr
    FULL OUTER JOIN 
        SupplierDetails sd ON tr.nation_name = LEFT(sd.s_name, LENGTH(tr.nation_name))
)
SELECT 
    fr.nation_name,
    fr.total_sales,
    fr.s_name,
    fr.total_supply_cost,
    fr.net_sales
FROM 
    FinalReport fr
WHERE 
    (fr.total_sales IS NOT NULL AND fr.total_sales > 10000)
    OR (fr.total_supply_cost IS NULL AND fr.net_sales < 5000)
ORDER BY 
    fr.nation_name, fr.net_sales DESC;
