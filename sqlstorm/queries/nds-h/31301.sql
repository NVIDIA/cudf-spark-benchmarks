
WITH  SupplierPurchases AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT  
        s.s_suppkey,
        s.s_name,
        sp.total_spent,
        sp.order_count,
        RANK() OVER (ORDER BY sp.total_spent DESC) AS supplier_rank
    FROM 
        SupplierPurchases sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.rn = 1
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(l.l_linenumber) AS line_item_count,
        o.o_orderstatus,
        COALESCE(c.c_name, 'Unknown') AS customer_name
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus, c.c_name
),
FinalReport AS (
    SELECT 
        ods.o_orderkey,
        ods.order_total,
        ods.o_orderdate AS order_date,
        ods.line_item_count,
        ods.o_orderstatus AS order_status,
        ts.s_name AS top_supplier
    FROM 
        OrderDetails ods
    LEFT JOIN 
        TopSuppliers ts ON ods.order_total > 1000
    WHERE 
        ods.o_orderstatus IN ('F', 'P')
)
SELECT 
    fr.o_orderkey,
    fr.order_total,
    fr.order_date,
    fr.line_item_count,
    fr.order_status,
    COALESCE(fr.top_supplier, 'N/A') AS supplier_name
FROM 
    FinalReport fr
WHERE 
    fr.line_item_count > 1
ORDER BY 
    fr.order_total DESC, fr.order_date ASC
LIMIT 100;
