WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.supply_count,
        sd.total_supply_cost
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    ol.total_revenue,
    ol.line_item_count,
    ol.avg_quantity,
    ts.s_suppkey,
    ts.s_name
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineDetails ol ON o.o_orderkey = ol.l_orderkey
FULL OUTER JOIN 
    TopSuppliers ts ON o.o_orderkey = ts.s_suppkey
WHERE 
    (o.o_orderstatus = 'O' OR o.o_orderstatus = 'F')
    AND ts.s_suppkey IS NOT NULL
ORDER BY 
    ol.total_revenue DESC, o.o_orderdate ASC;