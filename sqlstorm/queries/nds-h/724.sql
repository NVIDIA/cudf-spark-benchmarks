WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        total_avail_qty,
        avg_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierAvailability sa ON s.s_suppkey = sa.ps_partkey
    WHERE 
        sa.total_avail_qty > 100
),
CustomerCounts AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    pa.total_avail_qty,
    pa.avg_supply_cost,
    rc.o_orderkey,
    rc.o_orderdate,
    rc.o_totalprice,
    rc.c_name,
    cc.customer_count
FROM 
    part p
LEFT JOIN 
    SupplierAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    RankedOrders rc ON p.p_partkey = rc.o_orderkey
JOIN 
    CustomerCounts cc ON rc.rank_order <= 5
WHERE 
    p.p_retailprice > 50
    AND pa.avg_supply_cost IS NOT NULL
ORDER BY 
    p.p_name ASC, 
    rc.o_totalprice DESC;