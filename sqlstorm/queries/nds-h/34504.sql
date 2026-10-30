
WITH  total_sales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
region_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ts.total_amount) AS regional_sales
    FROM 
        total_sales ts
    JOIN 
        customer c ON ts.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
supplier_part_summary AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    rs.nation_name,
    rs.region_name,
    COALESCE(rs.regional_sales, 0) AS total_sales,
    sps.unique_parts,
    sps.total_supply_cost,
    CASE 
        WHEN rs.regional_sales > sps.total_supply_cost THEN 'Profit'
        WHEN rs.regional_sales < sps.total_supply_cost THEN 'Loss'
        ELSE 'Break-even'
    END AS financial_status
FROM 
    region_sales rs
FULL OUTER JOIN 
    supplier_part_summary sps ON rs.region_name IS NOT NULL AND sps.s_suppkey IS NOT NULL
WHERE 
    (rs.regional_sales IS NOT NULL OR sps.total_supply_cost IS NOT NULL)
ORDER BY 
    financial_status DESC,
    total_sales DESC;
