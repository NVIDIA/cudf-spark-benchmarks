WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ts.total_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available_quantity,
        ss.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_available_quantity DESC) AS supplier_rank
    FROM 
        SupplierStats ss
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_brand,
    tp.p_retailprice,
    tp.total_sales,
    ts.s_suppkey AS top_supplier_s_id,
    ts.s_name AS top_supplier_name,
    TS.total_available_quantity,
    TS.avg_supply_cost
FROM 
    TopParts tp
LEFT JOIN 
    TopSuppliers ts ON tp.sales_rank = ts.supplier_rank
WHERE 
    tp.sales_rank <= 10 AND (ts.total_available_quantity IS NULL OR ts.total_available_quantity > 100)
ORDER BY 
    tp.total_sales DESC
LIMIT 20;