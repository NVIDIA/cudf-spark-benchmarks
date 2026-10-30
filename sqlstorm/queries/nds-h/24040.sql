
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate < '1998-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        n.n_name
), HighValueRegions AS (
    SELECT 
        nation_name,
        total_sales,
        order_count,
        NTILE(3) OVER (ORDER BY total_sales DESC) AS sales_tier
    FROM 
        RegionalSales
), SupplierDetails AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), BizarrePreferences AS (
    SELECT 
        COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
        CASE 
            WHEN sd.part_count > 0 THEN 'Supplies Parts'
            ELSE 'No Supplies'
        END AS supply_status,
        CASE 
            WHEN sd.total_supply_cost IS NULL THEN 0
            ELSE sd.total_supply_cost / NULLIF(sd.part_count, 0)
        END AS avg_supply_cost_per_part,
        hvr.nation_name
    FROM 
        SupplierDetails sd
    FULL OUTER JOIN HighValueRegions hvr ON sd.s_name = hvr.nation_name
)
SELECT 
    b.supplier_name,
    b.supply_status,
    b.avg_supply_cost_per_part,
    hvr.total_sales,
    hvr.order_count,
    hvr.sales_tier
FROM 
    BizarrePreferences b
LEFT JOIN 
    HighValueRegions hvr ON b.nation_name = hvr.nation_name
WHERE 
    hvr.total_sales IS NOT NULL OR b.supply_status = 'No Supplies'
ORDER BY 
    COALESCE(hvr.total_sales, 0) DESC, 
    b.avg_supply_cost_per_part ASC
LIMIT 50;
