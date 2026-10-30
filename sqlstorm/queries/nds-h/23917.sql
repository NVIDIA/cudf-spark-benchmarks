
WITH  sales_data AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        (p.p_retailprice * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY (p.p_retailprice * ps.ps_availqty) DESC) AS rank_supply
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    sd.c_name,
    COALESCE(spi.s_name, 'No Supplier') AS supplier_name,
    sd.total_sales,
    COALESCE(spi.total_supply_value, 0) AS total_supply_value,
    CASE 
        WHEN sd.total_sales > COALESCE(spi.total_supply_value, 0) THEN 'Sales Exceed Supply'
        WHEN sd.total_sales < COALESCE(spi.total_supply_value, 0) THEN 'Supply Exceed Sales'
        ELSE 'Sales Equal Supply'
    END AS sales_vs_supply
FROM 
    sales_data sd
LEFT JOIN 
    supplier_part_info spi ON sd.c_custkey = spi.s_suppkey
WHERE 
    sd.rank_sales = 1 
    OR (spi.total_supply_value IS NULL AND sd.c_custkey IN (SELECT c_custkey FROM sales_data WHERE total_sales < 1000))
ORDER BY 
    sd.total_sales DESC, supplier_name ASC;
