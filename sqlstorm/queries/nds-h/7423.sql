WITH ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ps.p_name,
    COALESCE(ps.total_sales, 0) AS total_sales,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    CASE 
        WHEN COALESCE(ps.total_sales, 0) > 0 THEN (COALESCE(ss.total_supply_value, 0) / COALESCE(ps.total_sales, 1))
        ELSE 0
    END AS supply_to_sales_ratio
FROM 
    ProductSales ps
FULL OUTER JOIN 
    SupplierSummary ss ON ps.p_partkey = ss.s_suppkey
ORDER BY 
    supply_to_sales_ratio DESC
LIMIT 100;