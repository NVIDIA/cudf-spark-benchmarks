WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderstatus IN ('O', 'F')
),
SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_discount) AS max_discount
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderpriority,
    sd.s_name AS supplier_name,
    sd.total_supply_cost,
    os.order_total,
    os.avg_quantity,
    os.max_discount
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierData sd ON sd.part_count >= 5
LEFT JOIN 
    OrderStats os ON os.o_orderkey = r.o_orderkey
WHERE 
    r.rnk <= 10
AND 
    (sd.total_supply_cost IS NOT NULL OR os.order_total IS NOT NULL)
ORDER BY 
    r.o_orderdate DESC, 
    r.o_orderpriority;