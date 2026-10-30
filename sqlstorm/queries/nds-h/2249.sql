WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-12-31'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        s.total_avail_qty,
        s.total_supply_cost,
        CASE 
            WHEN s.total_avail_qty IS NULL THEN 'Out of Stock'
            WHEN s.total_avail_qty < 50 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        part p
    LEFT JOIN 
        SupplierAvailability s ON p.p_partkey = s.ps_partkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    r.c_name,
    p.p_name,
    p.stock_status,
    (p.p_retailprice * (1 - l.l_discount)) AS final_price
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    PartDetails p ON l.l_partkey = p.p_partkey
WHERE 
    r.rn <= 3
    AND p.stock_status != 'Out of Stock'
ORDER BY 
    r.o_totalprice DESC, 
    r.o_orderdate ASC;