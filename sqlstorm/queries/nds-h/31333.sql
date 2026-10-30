WITH  MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS sales_year,
        EXTRACT(MONTH FROM o_orderdate) AS sales_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        sales_year, sales_month
),
SupplierStats AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps_partkey) AS supply_count,
        SUM(ps_supplycost * ps_availqty) AS total_supply_value 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, n.n_nationkey
)
SELECT 
    m.sales_year,
    m.sales_month,
    MAX(n.nation_name) AS top_nation_supplier,
    SUM(m.total_sales) AS total_sales,
    SUM(p.avg_supply_cost) AS average_supply_cost_per_part
FROM 
    MonthlySales m
LEFT JOIN 
    NationSupplier n ON n.rn = 1
LEFT JOIN 
    PartDetails p ON p.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
WHERE 
    m.total_sales > 1000  
GROUP BY 
    m.sales_year, m.sales_month
ORDER BY 
    m.sales_year, m.sales_month;