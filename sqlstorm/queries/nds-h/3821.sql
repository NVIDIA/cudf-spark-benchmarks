WITH TotalSales AS (
    SELECT 
        SUM(l_extendedprice * (1 - l_discount)) AS total_price,
        l_partkey,
        l_orderkey
    FROM 
        lineitem
    WHERE 
        l_shipdate > DATE '1997-01-01'
    GROUP BY 
        l_partkey, l_orderkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ts.total_price), 0) AS sales_total,
        COALESCE(MAX(ss.supplier_cost), 0) AS max_supplier_cost
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN 
        SupplierSales ss ON p.p_partkey = ss.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.sales_total,
    pd.max_supplier_cost,
    CASE 
        WHEN pd.sales_total > 1000 THEN 'High Sales'
        WHEN pd.sales_total IS NULL OR pd.sales_total = 0 THEN 'No Sales'
        ELSE 'Average Sales'
    END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY pd.sales_total DESC) AS rank
FROM 
    PartDetails pd
WHERE 
    (pd.sales_total > 0 OR pd.max_supplier_cost > 0)
ORDER BY 
    pd.sales_total DESC, pd.p_name
LIMIT 10;