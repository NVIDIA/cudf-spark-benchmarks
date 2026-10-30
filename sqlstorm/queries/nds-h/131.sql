
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_supplycost) AS total_cost
    FROM 
        nation n
    LEFT JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    ns.n_name AS Nation, 
    ns.supplier_count AS Supplier_Count, 
    ns.total_cost AS Total_Supplier_Cost, 
    SUM(od.order_value) AS Total_Order_Value,
    AVG(od.line_item_count) AS Average_Line_Items 
FROM 
    NationSummary ns
LEFT JOIN 
    OrderDetails od ON ns.n_nationkey = od.o_custkey 
GROUP BY 
    ns.n_name, ns.supplier_count, ns.total_cost
HAVING 
    SUM(od.order_value) > 10000 
ORDER BY 
    Total_Order_Value DESC;
