WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_partkey
),
SupplierSales AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, s.s_suppkey
),
HighRevenueParts AS (
    SELECT 
        ts.l_partkey,
        ts.total_revenue,
        ss.total_supplier_cost,
        ts.total_revenue - ss.total_supplier_cost AS profit_margin
    FROM 
        TotalSales ts
    JOIN 
        SupplierSales ss ON ts.l_partkey = ss.p_partkey
    WHERE 
        ts.total_revenue > 1000000
)
SELECT 
    p.p_partkey,
    p.p_name,
    hr.total_revenue,
    hr.total_supplier_cost,
    hr.profit_margin
FROM 
    HighRevenueParts hr
JOIN 
    part p ON hr.l_partkey = p.p_partkey
ORDER BY 
    hr.profit_margin DESC
LIMIT 10;