WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY 
        o.o_orderkey
),
SupplierOrderInfo AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    COALESCE(HO.total_sales, 0) AS total_order_sales,
    COALESCE(SO.unique_suppliers, 0) AS unique_supplier_count,
    SO.total_quantity AS total_quantity_ordered
FROM 
    part p
LEFT OUTER JOIN 
    RankedSuppliers RS ON p.p_partkey = RS.s_suppkey
LEFT OUTER JOIN 
    HighValueOrders HO ON RS.s_suppkey = HO.o_orderkey
LEFT OUTER JOIN 
    SupplierOrderInfo SO ON HO.o_orderkey = SO.l_orderkey
WHERE 
    p.p_retailprice > 100 
    AND (p.p_comment IS NULL OR p.p_comment <> '')
ORDER BY 
    total_order_sales DESC, 
    p.p_name ASC;
