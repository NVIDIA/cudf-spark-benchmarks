WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
), SupplierOrderStats AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.supplier_nation,
        SUM(od.total_revenue) AS total_sales,
        AVG(od.o_totalprice) AS average_order_value,
        COUNT(od.o_orderkey) AS total_orders
    FROM 
        SupplierInfo si
    JOIN 
        partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY 
        si.s_suppkey, si.s_name, si.supplier_nation
)
SELECT 
    s.s_name,
    s.supplier_nation,
    COALESCE(SUM(sos.total_sales), 0) AS total_sales,
    COALESCE(AVG(sos.average_order_value), 0) AS average_order_value,
    COALESCE(SUM(sos.total_orders), 0) AS total_orders
FROM 
    SupplierInfo s
LEFT JOIN 
    SupplierOrderStats sos ON s.s_suppkey = sos.s_suppkey
GROUP BY 
    s.s_name, s.supplier_nation
ORDER BY 
    total_sales DESC
LIMIT 10;