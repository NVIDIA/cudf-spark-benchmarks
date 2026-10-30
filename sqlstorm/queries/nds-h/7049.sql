WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_costs
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice) AS total_lineitem_price,
        SUM(l.l_discount) AS total_discount,
        COUNT(DISTINCT l.l_linenumber) AS total_lineitems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CostAnalysis AS (
    SELECT 
        ss.s_suppkey,
        ss.total_available_qty,
        ss.total_costs,
        COALESCE(od.total_lineitem_price, 0) AS total_lineitem_price,
        COALESCE(od.total_discount, 0) AS total_discount
    FROM 
        SupplierStats ss
    LEFT JOIN 
        OrderDetails od ON ss.s_suppkey = od.o_orderkey
)
SELECT 
    ca.s_suppkey,
    ca.total_available_qty,
    ca.total_costs,
    ca.total_lineitem_price,
    ca.total_discount,
    (ca.total_lineitem_price - ca.total_discount) AS net_revenue
FROM 
    CostAnalysis ca
ORDER BY 
    ca.total_costs DESC
LIMIT 10;
