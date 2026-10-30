
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierSummary AS (
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
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(fo.total_price_after_discount, 0) AS total_discounted_price,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.avg_supply_cost
FROM 
    RankedOrders o
LEFT JOIN 
    CustomerOrderCounts cc ON o.o_orderkey = cc.c_custkey
LEFT JOIN 
    FilteredLineItems fo ON o.o_orderkey = fo.l_orderkey
LEFT JOIN 
    partsupp ps ON o.o_orderkey = ps.ps_partkey
LEFT JOIN 
    SupplierSummary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    customer c ON cc.c_custkey = c.c_custkey
WHERE 
    o.rn = 1 
    AND (ss.total_available_quantity IS NULL OR ss.total_available_quantity > 100)
ORDER BY 
    o.o_orderdate DESC, total_discounted_price DESC;
