WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighVolumeSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost IS NOT NULL
),
OrderLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    COALESCE(ols.total_line_price, 0) AS total_line_price,
    CASE 
        WHEN r.order_rank <= 10 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_classification,
    hs.s_name,
    hs.total_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    OrderLines ols ON r.o_orderkey = ols.l_orderkey
LEFT JOIN 
    HighVolumeSuppliers hs ON hs.cost_rank <= 5
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
    AND hs.s_name IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;