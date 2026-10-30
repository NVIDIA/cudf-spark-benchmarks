WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
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
        ss.total_supply_value,
        RANK() OVER(ORDER BY ss.total_supply_value DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supply_value > 10000
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ts.s_name,
    lis.total_revenue,
    lis.item_count,
    CASE 
        WHEN o.o_totalprice > 50000 THEN 'High Value Order'
        ELSE 'Regular Order'
    END AS order_type
FROM 
    RankedOrders o
JOIN 
    LineItemSummary lis ON o.o_orderkey = lis.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON ts.supplier_rank = 1
WHERE 
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey
        AND l.l_shipdate > '1997-01-01'
    )
ORDER BY 
    o.o_orderdate DESC,
    o.o_orderkey;