WITH RecursiveSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part AS p
    JOIN 
        lineitem AS l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT 
        p_partkey,
        p_name,
        total_sales
    FROM 
        RecursiveSales
    WHERE 
        sales_rank = 1
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    LEFT JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ts.p_name,
    sd.s_name,
    sd.part_count,
    sd.total_supply_cost,
    CASE 
        WHEN sd.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Has Supply Cost'
    END AS supply_cost_status,
    RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
FROM 
    TopSales AS ts
FULL OUTER JOIN 
    SupplierDetails AS sd ON ts.p_partkey = sd.part_count
WHERE 
    EXISTS (SELECT * FROM orders o WHERE o.o_orderkey = (
        SELECT MAX(o_orderkey) 
        FROM orders 
        WHERE o_orderstatus IN ('O', 'F') 
        AND o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
    )) 
    AND (sd.total_supply_cost >= (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) OR sd.total_supply_cost IS NULL)
ORDER BY 
    ts.total_sales DESC NULLS LAST, 
    sd.part_count DESC;